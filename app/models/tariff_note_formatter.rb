# Transforms raw tariff note content (as stored by the ETL pipeline) into valid
# Govspeak markdown before it is passed to GovspeakPreview for rendering.
#
# The ETL output is plain text — it has no indentation, no bold markers, no heading
# markup, and uses • bullets and — em-dash rows. Without this formatter those
# elements either render as code blocks (4-space indent outside a list), literal
# asterisks, or unstyled paragraphs.
#
# Rules applied (in priority order):
#   Note spacing  "1.Text" → "1. Text" so Govspeak recognises the list marker.
#   Rule 1        — em-dash pairs → a two-column Govspeak table (blank header).
#   Rule 2        Known section headings ("Subheading notes", "Additional section
#                 notes") → ### heading, which also resets the ordered list counter.
#   Rule 3        Lettered sub-items (a., b., ij.) → 4-space indent; bolded when
#                 the text looks like a definition title (starts uppercase, no
#                 terminal period, does not trail with ' and'/' or').
#   Rule 4        Capital-bracket sub-paragraphs (B)–(Z) → 4-space indent only.
#                 Starts at B because (A) always appears inline with the note number
#                 ("1. (A) ...") and is never a standalone line.
#   Rule 5        Lowercase-bracket sub-items (a)–(z) → same bold heuristic as rule 3.
#   Rule 6        Numbered-bracket sub-sub-items (1), (2) → 4-space indent only.
#   Rule 7        • bullet → Govspeak sub-bullet "  - ".
#   Rule 8        Plain prose lines belonging to a numbered note (no match from
#                 rules 1–7) are indented 4 spaces. Govspeak renders 4-space content
#                 after an "N." list marker as a <p> inside the <li>; without the
#                 indent the prose becomes a detached top-level paragraph.
#
#                   ETL in:  "1. Note heading.\n\nContinuation prose."
#                   Out:     "1. Note heading.\n\n    Continuation prose."
#
class TariffNoteFormatter
  SECTION_HEADINGS = ["Subheading notes", "Additional section notes"].freeze

  def initialize(content)
    @content = content.to_s
  end

  def format
    lines = normalize(@content).split("\n")
    result = []
    in_note = false
    i = 0

    while i < lines.length
      line = lines[i]

      # Normalise missing space after note number: "1.Text" → "1. Text"
      line = line.sub(/\A(\d+)\.([^\s])/, '\1. \2')

      # Rule 1: em-dash table (multi-line — must run before any line rule)
      if line.start_with?("—")
        rows, consumed = extract_emdash_rows(lines, i)
        result.concat(render_emdash_table(rows))
        i += consumed
        next
      end

      if line.match?(/\A\d+\./)
        in_note = true
        result << line
      elsif line.strip.empty?
        result << line
      elsif (transformed = transform_line(line))
        result << transformed
      elsif in_note
        result << "    #{line}"
      else
        result << line
      end

      i += 1
    end

    result.join("\n")
  end

private

  def normalize(content)
    content.gsub("\r\n", "\n").gsub("\r", "\n")
  end

  def transform_line(line)
    # Rule 2: known section headings — must be first so rule 8 cannot indent them
    return "### #{line}" if SECTION_HEADINGS.include?(line)

    # Rule 3: lettered sub-items (a., b., ..., ij.)
    if (m = line.match(/\A([a-z]{1,2})\. (.+)/))
      label = m[1]
      rest = m[2]
      return definition_title?(rest) ? "    **#{label}. #{rest}**" : "    #{label}. #{rest}"
    end

    # Rule 4: capital bracket sub-paragraphs (B)-(Z) — indent only, never bold
    if (m = line.match(/\A\(([B-Z])\) (.+)/))
      return "    (#{m[1]}) #{m[2]}"
    end

    # Rule 5: lowercase bracket sub-items (a)-(z)
    if (m = line.match(/\A\(([a-z])\) (.+)/))
      label = m[1]
      rest = m[2]
      return definition_title?(rest) ? "    **(#{label}) #{rest}**" : "    (#{label}) #{rest}"
    end

    # Rule 6: numbered bracket sub-sub-items
    if (m = line.match(/\A\((\d+)\) (.+)/))
      return "    (#{m[1]}) #{m[2]}"
    end

    # Rule 7: bullet character
    if (m = line.match(/\A•\s*(.*)/))
      return "  - #{m[1]}"
    end

    nil
  end

  def definition_title?(text)
    text.match?(/\A[A-Z]/) && !text.end_with?(".") && !text.end_with?(" and") && !text.end_with?(" or")
  end

  def extract_emdash_rows(lines, start_i)
    rows = []
    i = start_i

    while i < lines.length && (m = lines[i].match(/\A—\s*(.*)/))
      description = "— #{m[1].strip}"
      i += 1
      break unless i < lines.length

      rows << [description, lines[i].strip]
      i += 1
    end

    [rows, i - start_i]
  end

  def render_emdash_table(rows)
    output = ["|   |   |", "|---|---|"]
    rows.each { |desc, val| output << "| #{desc} | #{val} |" }
    output
  end
end
