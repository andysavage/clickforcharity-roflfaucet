#!/bin/bash
# Linear Include Processor
# Processes <!-- include start xxx --> and <!-- include end xxx --> tags
# Clean, fast template system for SatoshiHost network sites

echo "🔨 Building HTML files with includes..."

# Function to process includes in a file - linear single pass
process_includes() {
    local input_file="$1"
    local output_file="$2"
    local temp_file=$(mktemp)
    
    echo "📄 Processing: $input_file → $output_file"
    
    # Add warning header to output file
    template_name=$(basename "$input_file")
    cat > "$temp_file" << EOF
<!-- ⚠️  WARNING: This file is AUTO-GENERATED by build.sh ⚠️ -->
<!-- 🚨 DO NOT EDIT THIS FILE DIRECTLY! 🚨 -->
<!-- -->
<!-- ✏️  To make changes, edit the template file instead: -->
<!-- 📁 templates/$template_name -->
<!-- -->
<!-- 🔧 Then run: ./build.sh -->
<!-- ⚠️  All direct edits to this file will be LOST! ⚠️ -->
<!-- ================================================================ -->

EOF
    
    # Process file line by line
    local in_include=false
    local include_name=""
    
    while IFS= read -r line; do
        # Check for include start tag
        if [[ "$line" =~ \<!--[[:space:]]*include[[:space:]]+start[[:space:]]+([^[:space:]]+)[[:space:]]*--\> ]]; then
            include_name="${BASH_REMATCH[1]}"
            in_include=true
            echo "  📎 Including: $include_name"
            
            # Add the start comment
            echo "$line" >> "$temp_file"
            
            # Add the include file content
            include_path="includes/$include_name"
            
            if [[ -f "$include_path" ]]; then
                cat "$include_path" >> "$temp_file"
            else
                echo "  ⚠️  Include file not found: $include_path"
                echo "<!-- ERROR: Include file not found: $include_path -->" >> "$temp_file"
            fi
            
        # Check for include end tag
        elif [[ "$line" =~ \<!--[[:space:]]*include[[:space:]]+end[[:space:]]+([^[:space:]]+)[[:space:]]*--\> ]]; then
            end_include_name="${BASH_REMATCH[1]}"
            
            if [[ "$end_include_name" == "$include_name" ]]; then
                # Add the end comment
                echo "$line" >> "$temp_file"
                in_include=false
                include_name=""
            else
                echo "  ⚠️  Mismatched include tags: started with '$include_name' but ended with '$end_include_name'"
                echo "$line" >> "$temp_file"
            fi
            
        # Regular line - only add if we're not inside an include block
        elif [[ "$in_include" == false ]]; then
            echo "$line" >> "$temp_file"
        fi
        # If we're inside an include block, skip the line (it gets replaced by include content)
        
    done < "$input_file"
    
    # Move final result to output
    mv "$temp_file" "$output_file"
    echo "  ✅ Built: $output_file"
}

# Build all template files
template_count=0

# Process both .template.html and .tmpl files
for template in templates/*.template.html templates/*.tmpl; do
    if [[ -f "$template" ]]; then
        # Extract filename and determine output name
        if [[ "$template" == *.template.html ]]; then
            basename=$(basename "$template" .template.html)
            output_file="${basename}.html"
        elif [[ "$template" == *.tmpl ]]; then
            basename=$(basename "$template" .tmpl)
            output_file="${basename}.html"
        fi
        
        process_includes "$template" "$output_file"
        ((template_count++))
    fi
done

if [[ $template_count -eq 0 ]]; then
    echo "📁 No template files found in templates/ directory"
    echo "💡 Create files like templates/page.template.html or templates/page.tmpl to get started"
else
    echo ""
    echo "🎉 Build complete! Processed $template_count template(s)"
    echo ""
    echo "📝 Template syntax (choose your style):"
    echo "   Simple:    <!--#include file=\"includes/header.html\" -->"
    echo "   BBEdit:    <!-- #bbinclude \"header.html\""
    echo "              #TITLE#=\"Page Title\""
    echo "              #KEYWORDS#=\"seo, keywords\""
    echo "              -->"
    echo ""
    echo "📂 Directory structure:"
    echo "   templates/           - Your .template.html or .tmpl source files"
    echo "   includes/           - Shared HTML snippets with #PLACEHOLDER# support"
    echo "   *.html              - Generated output files"
fi

# Ensure script exits with success
exit 0

