#!/bin/bash
# Kiểm tra cấu trúc và frontmatter của toàn bộ skills trong skills/.
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ruby lấy source encoding của -e từ locale; ép UTF-8 để đọc được tiếng Việt.
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANG="${LANG:-en_US.UTF-8}"

ruby -ryaml -e '
root = ARGV[0]
bad = []
count = 0

Dir.glob(File.join(root, "skills", "*")).select { |d| File.directory?(d) }.sort.each do |dir|
  name = File.basename(dir)
  count += 1

  # --- SKILL.md ---
  skill = File.join(dir, "SKILL.md")
  if !File.exist?(skill)
    bad << "#{name}: thiếu SKILL.md"
  else
    txt = File.read(skill, encoding: "utf-8")
    if txt =~ /\A---\n(.*?)\n---\n/m
      begin
        fm = YAML.safe_load($1)
        bad << "#{name}: SKILL.md thiếu field name"        unless fm["name"]
        bad << "#{name}: SKILL.md thiếu field description" unless fm["description"]
        if fm["name"] && fm["name"] != name
          bad << "#{name}: name=\"#{fm["name"]}\" không khớp tên thư mục"
        end
      rescue => e
        bad << "#{name}: frontmatter YAML lỗi -> #{e.message}"
      end
    else
      bad << "#{name}: SKILL.md thiếu YAML frontmatter"
    end
  end

  # --- agents/openai.yaml ---
  agents = File.join(dir, "agents", "openai.yaml")
  if !File.exist?(agents)
    bad << "#{name}: thiếu agents/openai.yaml"
  else
    begin
      data = YAML.safe_load(File.read(agents, encoding: "utf-8"))
      bad << "#{name}: agents thiếu interface.display_name"      unless data.dig("interface", "display_name")
      bad << "#{name}: agents thiếu interface.short_description" unless data.dig("interface", "short_description")
    rescue => e
      bad << "#{name}: agents/openai.yaml YAML lỗi -> #{e.message}"
    end
  end

  # --- references/ ---
  bad << "#{name}: thiếu thư mục references/" unless File.directory?(File.join(dir, "references"))
end

puts "Đã kiểm tra #{count} skill."
if bad.empty?
  puts "\e[0;32m✓ Tất cả hợp lệ.\e[0m"
else
  puts "\e[0;31mPhát hiện #{bad.size} vấn đề:\e[0m"
  bad.each { |b| puts "  ✗ #{b}" }
  exit 1
end
' "$REPO_DIR"
