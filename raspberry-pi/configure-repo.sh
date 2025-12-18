#!/bin/bash
#
# Configure the setup scripts for your GitHub repository
#

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <github-username>"
    echo "Example: $0 nbm"
    exit 1
fi

GITHUB_USERNAME="$1"
REPO_NAME="prismgb-app"

echo "========================================="
echo "Configuring for GitHub repo:"
echo "https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
echo "========================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Update setup.sh
echo "Updating setup.sh..."
sed -i.bak "s|github.com/josstei/prismgb-app|github.com/${GITHUB_USERNAME}/${REPO_NAME}|g" "$SCRIPT_DIR/setup.sh"
sed -i.bak "s|github.com/YOUR_USERNAME/prismgb-app|github.com/${GITHUB_USERNAME}/${REPO_NAME}|g" "$SCRIPT_DIR/setup.sh"

# Update README.md
echo "Updating README.md..."
sed -i.bak "s|github.com/josstei/prismgb-app|github.com/${GITHUB_USERNAME}/${REPO_NAME}|g" "$SCRIPT_DIR/README.md"
sed -i.bak "s|github.com/YOUR_USERNAME/prismgb-app|github.com/${GITHUB_USERNAME}/${REPO_NAME}|g" "$SCRIPT_DIR/README.md"

# Update other files
echo "Updating other documentation..."
for file in DEPLOYMENT.md CURRENT-STATUS.md; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        sed -i.bak "s|github.com/josstei/prismgb-app|github.com/${GITHUB_USERNAME}/${REPO_NAME}|g" "$SCRIPT_DIR/$file"
        sed -i.bak "s|github.com/YOUR_USERNAME/prismgb-app|github.com/${GITHUB_USERNAME}/${REPO_NAME}|g" "$SCRIPT_DIR/$file"
    fi
done

# Clean up backup files
rm -f "$SCRIPT_DIR"/*.bak

echo ""
echo "✅ Configuration complete!"
echo ""
echo "URLs now point to: https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
echo ""
echo "Next steps:"
echo "1. git add ."
echo "2. git commit -m 'Add Raspberry Pi setup'"
echo "3. git push origin main"
echo "4. npm run package:rpi-source"
echo "5. Create GitHub release v1.1.0 and upload prismgb-source-1.1.0.tar.gz"
echo ""