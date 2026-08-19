#!/usr/bin/env ruby
# frozen_string_literal: true

# Imports the lab's canonical BibTeX file without requiring a second Git checkout
# inside the public website repository. Entries tagged with the `selected`
# keyword are translated to the field al-folio uses on the homepage.

source_path, destination_path = ARGV
abort "Usage: ruby bin/import_bibliography.rb SOURCE.bib DESTINATION.bib" unless source_path && destination_path

source = File.read(source_path).sub(/\A---\s*\n---\s*\n+/, "")

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

def add_selected_field(entry)
  return entry if entry.match?(/\bselected\s*=/i) || !selected_keyword?(entry)

  closing = entry[-1]
  body = entry[0...-1].rstrip
  separator = body.end_with?(",") ? "" : ","
  "#{body}#{separator}\n  selected = {true}\n#{closing}"
end

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
  imported_entry = add_selected_field(raw_entry)
  selected += 1 if imported_entry.match?(/\bselected\s*=\s*[\{"]true/i)
  output << imported_entry
  imported += 1
  cursor = metadata[:finish]
end

output << source[cursor..]
clean_output = output.lines.map(&:rstrip).join("\n")
File.write(destination_path, clean_output.rstrip + "\n")
puts "Imported #{imported} publications (#{selected} selected) into #{destination_path}"
