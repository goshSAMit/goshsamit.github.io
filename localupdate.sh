obsidianContentPath="/home/sam/Documents/Obsidian Vault/content"
hugoContentPath="/home/sam/website/goshsamit.github.io"

echo "Syncing files from Obsidian..."

if [ ! -d "$obsidianContentPath" ]; then
    echo "Source path does not exist: $obsidianContentPath"
    exit 1
fi

if [ ! -d "$hugoContentPath" ]; then
    echo "Destination path does not exist: $hugoContentPath"
    exit 1
fi

rsync -av --delete "$obsidianContentPath" "$hugoContentPath"

echo "Processing image links in Markdown files..."
if [ ! -f "images.py" ]; then
    echo "Python script images.py not found."
    exit 1
fi

if ! python3 images.py; then
    echo "Failed to process image links."
    exit 1
fi

hugo server
