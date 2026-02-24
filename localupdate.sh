# obsidianContentPath="/mnt/share/files/sam/Obsidian Vault/content" # UBUNTU PATH
# hugoContentPath="/home/sam/website/goshsamit.github.io" #UBUNTU PATH

obsidianContentPath="/Volumes/arnold/files/sam/Obsidian Vault/content" #MAC PATH
hugoContentPath="/Users/sam/projects/personal/goshsamit.github.io" #MAC PATH

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

hugo server --disableFastRender
