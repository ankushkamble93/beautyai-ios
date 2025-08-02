#!/bin/bash

echo "🔍 Checking all Swift files for syntax errors..."

# Find all Swift files and check their syntax
find . -name "*.swift" -print0 | while IFS= read -r -d '' file; do
    echo "Checking: $file"
    if swift -frontend -parse "$file" > /dev/null 2>&1; then
        echo "✅ $file - OK"
    else
        echo "❌ $file - HAS ERRORS"
        swift -frontend -parse "$file"
    fi
done

echo "🎉 Swift syntax check complete!" 