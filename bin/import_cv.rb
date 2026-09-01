#!/usr/bin/env ruby

require "yaml"

source_path, destination_path = ARGV
abort "usage: ruby bin/import_cv.rb path/to/cv.tex _data/cv.yml" unless source_path && destination_path
abort "CV source not found: #{source_path}" unless File.file?(source_path)

def clean_tex(value)
  text = value.to_s.dup
  loop do
    previous = text.dup
    text.gsub!(/\\(?:textbf|textit|underline|emph)\{([^{}]*)\}/, '\\1')
    break if text == previous
  end
  text.gsub!(/\\newline\b/, " ")
  text.gsub!(/\\&/, "&")
  text.gsub!(/\\\$/, "$")
  text.gsub!(/\\%/, "%")
  text.gsub!(/~/, " ")
  text.gsub!(/\\[a-zA-Z]+\*?(?:\[[^\]]*\])?/, "")
  text.gsub!(/[{}]/, "")
  text.gsub!(/\\\\/, " ")
  text.gsub!(/\s+/, " ")
  text.strip
end

def command_arguments(text, command)
  results = []
  cursor = 0
  marker = "\\#{command}"

  while (start = text.index(marker, cursor))
    index = start + marker.length
    args = []

    while args.length < 6
      index += 1 while index < text.length && text[index] =~ /\s/
      break unless text[index] == "{"

      depth = 0
      argument_start = index + 1
      index += 1
      while index < text.length
        if text[index] == "{" && text[index - 1] != "\\"
          depth += 1
        elsif text[index] == "}" && text[index - 1] != "\\"
          if depth.zero?
            args << text[argument_start...index]
            index += 1
            break
          end
          depth -= 1
        end
        index += 1
      end
    end

    results << { position: start, arguments: args } if args.length == 6
    cursor = [index, start + marker.length].max
  end

  results
end

def date_range(value)
  date = clean_tex(value).tr("–—", "-")
  years = date.scan(/\b(?:19|20)\d{2}\b/)
  return {} if years.empty?

  range = { "start_date" => years.first }
  range["end_date"] = if date.match?(/present/i) || date.match?(/#{Regexp.escape(years.first)}\s*--?\s*$/)
                        "Present"
                      elsif years.length > 1
                        years.last
                      else
                        years.first
                      end
  range
end

def sections(text)
  matches = []
  text.to_enum(:scan, /\\section\{([^{}]+)\}/).each do
    match = Regexp.last_match
    matches << [clean_tex(match[1]), match.begin(0), match.end(0)]
  end

  matches.each_with_index.to_h do |(title, _start, body_start), index|
    body_end = matches[index + 1]&.[](1) || text.length
    [title, text[body_start...body_end]]
  end
end

def subsection_at(body, position)
  candidates = []
  body.to_enum(:scan, /\\subsection\{([^{}]+)\}/).each do
    match = Regexp.last_match
    candidates << [match.begin(0), clean_tex(match[1])]
  end
  candidates.select { |candidate| candidate[0] < position }.last&.[](1)
end

def generic_entries(body)
  command_arguments(body.to_s, "cventry").map do |entry|
    args = entry[:arguments].map { |argument| clean_tex(argument) }
    subsection = subsection_at(body, entry[:position])
    parts = []
    parts << "**#{args[0]}**" unless args[0].empty?
    parts << args[1..4].reject(&:empty?).join(" — ")
    parts << args[5] unless args[5].empty?
    label = subsection && !subsection.empty? ? "**#{subsection}:** " : ""
    { "bullet" => "#{label}#{parts.reject(&:empty?).join('. ')}" }
  end
end

raw = File.read(source_path, encoding: "UTF-8")
text = raw.lines.map { |line| line.sub(/(?<!\\)%.*$/, "") }.join
source_sections = sections(text)

appointments = command_arguments(source_sections["Academic Appointments"].to_s, "cventry").map do |entry|
  args = entry[:arguments].map { |argument| clean_tex(argument) }
  {
    "company" => args[1],
    "position" => args[2],
    "location" => args[4],
    "summary" => [args[3], args[5]].reject(&:empty?).join(" · "),
  }.merge(date_range(args[0])).reject { |_key, value| value.nil? || value.empty? }
end

education = command_arguments(source_sections["Education & Training"].to_s, "cventry").map do |entry|
  args = entry[:arguments].map { |argument| clean_tex(argument) }
  {
    "institution" => args[1],
    "studyType" => args[2],
    "area" => args[3],
    "location" => args[4],
    "highlights" => args[5].empty? ? nil : [args[5]],
  }.merge(date_range(args[0])).reject { |_key, value| value.nil? || value.empty? }
end

awards = command_arguments(source_sections["Selected Honors and Awards"].to_s, "cventry").map do |entry|
  args = entry[:arguments].map { |argument| clean_tex(argument) }
  {
    "title" => args[2].empty? ? args[1] : args[2],
    "awarder" => args[1],
    "date" => args[0],
    "summary" => args[5],
  }.reject { |_key, value| value.nil? || value.empty? }
end

website_sections = {
  "Experience" => appointments,
  "Education" => education,
  "Research Support" => generic_entries(source_sections["Research Support"]),
  "Honors and Awards" => awards,
  "Invited Seminars" => generic_entries(source_sections["Invited Seminars"]),
  "Invited Conference Presentations" => generic_entries(source_sections["Invited Conference Presentations"]),
  "Student Conference Presentations" => generic_entries(source_sections["Student Conference Presentations"]),
  "Teaching" => generic_entries(source_sections["Teaching"]),
  "Research Advising" => generic_entries(source_sections["Research Advising"]),
  "University Service" => generic_entries(source_sections["University Service"]),
  "Scientific Community Service" => generic_entries(source_sections["Scientific Community Service"]),
}.reject { |_key, value| value.empty? }

cv = {
  "cv" => {
    "name" => "Ben Rachunok, Ph.D.",
    "label" => "Assistant Professor of Industrial and Systems Engineering",
    "email" => clean_tex(text[/\\email\{([^{}]+)\}/, 1]),
    "location" => "Raleigh, North Carolina",
    "image" => "people/IMG_3368.png",
    "summary" => "Ben Rachunok studies interconnected infrastructure and social systems to advance sustainable, resilient, and equitable communities under climate change and natural hazards.",
    "social_networks" => [
      { "network" => "GitHub", "username" => "brachunok" },
      { "network" => "ORCID", "username" => "0000-0001-6405-978X" },
    ],
    "sections" => website_sections,
  },
}

File.write(destination_path, YAML.dump(cv))
puts "Imported #{website_sections.values.sum(&:length)} CV entries from #{source_path}"
