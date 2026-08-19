#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

# Imports the lab's canonical BibTeX file without requiring a second Git checkout
# inside the public website repository. Entries tagged with the `selected`
# keyword are translated to the field al-folio uses on the homepage.

source_path, destination_path = ARGV
abort "Usage: ruby bin/import_bibliography.rb SOURCE.bib DESTINATION.bib" unless source_path && destination_path

source = File.read(source_path).sub(/\A---\s*\n---\s*\n+/, "")

def normalize_title(title)
  title.to_s
    .gsub(/\\[A-Za-z]+/, " ")
    .gsub(/[{}]/, "")
    .downcase
    .gsub(/[^a-z0-9]+/, " ")
    .strip
end

def field_value(entry, field)
  match = /\b#{Regexp.escape(field)}\s*=\s*(?:\{([^}]*)\}|"([^"]*)")/mi.match(entry)
  match && (match[1] || match[2])
end

def add_field(entry, field, value)
  return entry if field_value(entry, field)

  closing = entry[-1]
  body = entry[0...-1].rstrip
  separator = body.end_with?(",") ? "" : ","
  "#{body}#{separator}\n  #{field} = {#{value}}\n#{closing}"
end

def scholar_ids_by_title(path)
  return {} unless File.file?(path)

  data = YAML.safe_load_file(path) || {}
  (data["papers"] || {}).each_with_object({}) do |(publication_id, publication), matches|
    title = normalize_title(publication["title"])
    matches[title] = publication_id.to_s.split(":").last unless title.empty?
  end
rescue Psych::SyntaxError => error
  warn "Ignoring invalid Scholar citation data in #{path}: #{error.message}"
  {}
end

def entries_in(source)
  entries = []
  cursor = 0

  while (match = /@([A-Za-z]+)\s*([\{(])\s*([^,\s]+)\s*,/m.match(source, cursor))
    opening_index = match.begin(2)
    opening = match[2]
    closing = opening == "{" ? "}" : ")"
    depth = 0
    escaped = false
    closing_index = nil

    source[opening_index..].each_char.with_index(opening_index) do |character, index|
      if escaped
        escaped = false
        next
      end

      if character == "\\"
        escaped = true
      elsif character == opening
        depth += 1
      elsif character == closing
        depth -= 1
        if depth.zero?
          closing_index = index
          break
        end
      end
    end

    abort "Could not find the end of BibTeX entry #{match[3]}" unless closing_index

    entries << { start: match.begin(0), finish: closing_index + 1, key: match[3] }
    cursor = closing_index + 1
  end

  entries
end

def selected_keyword?(entry)
  match = /\bkeywords\s*=\s*(?:\{([^}]*)\}|"([^"]*)")/mi.match(entry)
  return false unless match

  (match[1] || match[2]).split(",").any? { |keyword| keyword.strip.casecmp("selected").zero? }
end

def student_author_indexes(entry)
  annotations = field_value(entry, "author+an")
  return [] unless annotations

  annotations.split(";").filter_map do |annotation|
    index, labels = annotation.split("=", 2)
    index.to_i if labels.to_s.split(",").any? { |label| label.strip.casecmp("student").zero? }
  end
end

def mark_student_authors(entry, indexes)
  return entry if indexes.empty? || entry.match?(/\bannotation\s*=/i)

  authors = field_value(entry, "author")
  return entry unless authors

  marked_authors = authors.split(/\s+and\s+/i).each_with_index.map do |author, index|
    next author unless indexes.include?(index + 1)

    if author.include?(",")
      author.sub(",", "*,")
    else
      author.sub(/(\S+)\s*\z/, "\\1*")
    end
  end.join(" and ")

  entry = entry.sub(/(\bauthor\s*=\s*)(\{[^}]*\}|"[^"]*")/mi) do
    opening = Regexp.last_match(2)[0]
    closing = Regexp.last_match(2)[-1]
    "#{Regexp.last_match(1)}#{opening}#{marked_authors}#{closing}"
  end
  add_field(entry, "annotation", "* Student author")
end

def enrich_entry(entry, scholar_ids)
  students = student_author_indexes(entry)
  unless students.empty?
    entry = mark_student_authors(entry, students)
    entry = add_field(entry, "student_paper", "true")
  end

  if selected_keyword?(entry)
    entry = add_field(entry, "selected", "true")
    entry = add_field(entry, "bibtex_show", "true")

    if field_value(entry, "doi")
      entry = add_field(entry, "altmetric", "true")
      entry = add_field(entry, "dimensions", "true")
    end
  end

  title = normalize_title(field_value(entry, "title"))
  scholar_id = scholar_ids[title]
  entry = add_field(entry, "google_scholar_id", scholar_id) if scholar_id
  entry
end

citations_path = ENV.fetch("CITATIONS_FILE", File.join(File.dirname(destination_path), "..", "_data", "citations.yml"))
scholar_ids = scholar_ids_by_title(citations_path)
output = +"---\n---\n\n"
cursor = 0
seen = {}
imported = 0
selected = 0

entries_in(source).each do |metadata|
  output << source[cursor...metadata[:start]]
  raw_entry = source[metadata[:start]...metadata[:finish]]
  comparison = raw_entry.gsub(/\s+/, " ").strip

  if seen.key?(metadata[:key])
    if seen[metadata[:key]] == comparison
      warn "Skipping exact duplicate BibTeX entry: #{metadata[:key]}"
      cursor = metadata[:finish]
      next
    end

    abort "Conflicting BibTeX entries use the same citation key: #{metadata[:key]}"
  end

  seen[metadata[:key]] = comparison
  imported_entry = enrich_entry(raw_entry, scholar_ids)
  selected += 1 if imported_entry.match?(/\bselected\s*=\s*[\{"]true/i)
  output << imported_entry
  imported += 1
  cursor = metadata[:finish]
end

output << source[cursor..]
clean_output = output.lines.map(&:rstrip).join("\n")
File.write(destination_path, clean_output.rstrip + "\n")
puts "Imported #{imported} publications (#{selected} selected) into #{destination_path}"
