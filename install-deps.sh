#!/bin/bash
# =============================================================================
# Claude Code Toolkit - System Dependencies Installer
# =============================================================================
# Installs all system packages, Python libraries, and Node modules needed
# by the toolkit's skills, hooks, and statusline.
#
# Run: bash install-deps.sh [--all | --system | --python | --node | --check]
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ─── System packages (apt) ──────────────────────────────────────────────────
install_system() {
    info "Installing system packages..."

    # Core tools (hooks, statusline, general usage)
    local CORE="jq curl bc git"

    # Document processing
    local DOCS="pandoc poppler-utils libreoffice qpdf"

    # Media processing
    local MEDIA="ffmpeg"

    # Screenshot/browser automation
    local BROWSER="xvfb"

    # Python build dependencies
    local PYTHON_DEPS="python3 python3-pip"

    # Node.js (if not already installed)
    local NODE_DEPS="nodejs npm"

    local ALL_PKGS="$CORE $DOCS $MEDIA $BROWSER $PYTHON_DEPS $NODE_DEPS"

    echo "  Packages: $ALL_PKGS"
    echo ""

    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y $ALL_PKGS
        success "System packages installed"
    elif command -v brew &>/dev/null; then
        # macOS - some packages have different names
        brew install jq curl bc git pandoc poppler qpdf ffmpeg node python3
        warn "libreoffice and xvfb must be installed manually on macOS"
        success "System packages installed (macOS)"
    else
        error "Neither apt-get nor brew found. Install packages manually:"
        echo "  $ALL_PKGS"
        return 1
    fi
}

# ─── Python packages (pip) ───────────────────────────────────────────────────
install_python() {
    info "Installing Python packages..."

    # PDF processing
    local PDF="pypdf pdfplumber reportlab pytesseract pdf2image"

    # Document processing
    local DOCS="openpyxl pandas defusedxml python-docx"

    # Web scraping
    local WEB="beautifulsoup4 lxml html5lib nodriver requests"

    # Media
    local MEDIA="pillow imageio numpy"

    # YouTube
    local YOUTUBE="youtube-transcript-api"

    # PPTX extraction
    local PPTX='markitdown[pptx]'

    local ALL_PIP="$PDF $DOCS $WEB $MEDIA $YOUTUBE"

    echo "  Packages: $ALL_PIP $PPTX"
    echo ""

    pip3 install --user --break-system-packages \
        $ALL_PIP "$PPTX" 2>/dev/null || \
    pip3 install --user \
        $ALL_PIP "$PPTX"

    success "Python packages installed"
}

# ─── Node packages (npm) ─────────────────────────────────────────────────────
install_node() {
    info "Installing Node.js packages..."

    local PACKAGES="playwright pptxgenjs docx sharp react react-dom react-icons"

    echo "  Packages: $PACKAGES"
    echo ""

    npm install -g $PACKAGES 2>/dev/null || {
        warn "npm install failed - trying with sudo..."
        sudo npm install -g $PACKAGES
    }

    # Install Playwright browsers
    info "Installing Playwright browsers (Chromium)..."
    npx playwright install chromium 2>/dev/null || \
        warn "Could not install Playwright browsers automatically"

    success "Node packages installed"
}

# ─── Whisper transcription (optional, heavy ~500MB) ──────────────────────────
install_whisper() {
    info "Installing faster-whisper for audio/video transcription..."
    warn "This downloads ~500MB of ML models"

    local WHISPER_DIR="$HOME/.local/share/whisper-env"

    if [ -d "$WHISPER_DIR" ]; then
        success "Whisper environment already exists at $WHISPER_DIR"
        return 0
    fi

    python3 -m venv "$WHISPER_DIR"
    "$WHISPER_DIR/bin/pip" install faster-whisper

    # Create global command
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/whisper-transcribe" << 'SCRIPT'
#!/bin/bash
source "$HOME/.local/share/whisper-env/bin/activate"
python3 -c "
import sys
from faster_whisper import WhisperModel
model = WhisperModel('base', device='cpu')
segments, info = model.transcribe(sys.argv[1], language=sys.argv[2] if len(sys.argv)>2 else None)
for segment in segments:
    print(f'[{segment.start:.2f} -> {segment.end:.2f}] {segment.text}')
" "$@"
SCRIPT
    chmod +x "$HOME/.local/bin/whisper-transcribe"

    success "Whisper installed to $WHISPER_DIR"
    info "Usage: whisper-transcribe <audio-file> [language]"
}

# ─── Check what's installed ──────────────────────────────────────────────────
check_deps() {
    echo ""
    echo "==========================================="
    echo " Dependency Check"
    echo "==========================================="
    echo ""

    local missing=0

    echo -e "${BLUE}System tools:${NC}"
    for cmd in jq curl bc git pandoc pdftotext libreoffice qpdf ffmpeg xvfb-run node npm python3 pip3; do
        if command -v "$cmd" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $cmd"
        else
            echo -e "  ${RED}✗${NC} $cmd"
            missing=$((missing + 1))
        fi
    done

    echo ""
    echo -e "${BLUE}Python packages:${NC}"
    for pkg in pypdf pdfplumber reportlab pytesseract pdf2image openpyxl pandas defusedxml bs4 lxml nodriver PIL imageio numpy youtube_transcript_api markitdown requests; do
        if python3 -c "import $pkg" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $pkg"
        else
            echo -e "  ${RED}✗${NC} $pkg"
            missing=$((missing + 1))
        fi
    done

    echo ""
    echo -e "${BLUE}Node packages:${NC}"
    for pkg in playwright pptxgenjs docx sharp react react-dom react-icons; do
        if npm list -g "$pkg" &>/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} $pkg"
        else
            echo -e "  ${RED}✗${NC} $pkg"
            missing=$((missing + 1))
        fi
    done

    echo ""
    echo -e "${BLUE}Optional:${NC}"
    if [ -d "$HOME/.local/share/whisper-env" ]; then
        echo -e "  ${GREEN}✓${NC} faster-whisper (audio/video transcription)"
    else
        echo -e "  ${YELLOW}○${NC} faster-whisper (run: bash install-deps.sh --whisper)"
    fi

    if command -v chromium-browser &>/dev/null || command -v google-chrome &>/dev/null || npx playwright install --dry-run chromium &>/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Chromium/Chrome (browser automation)"
    else
        echo -e "  ${YELLOW}○${NC} Chromium (run: npx playwright install chromium)"
    fi

    echo ""
    if [ $missing -eq 0 ]; then
        success "All dependencies installed!"
    else
        warn "$missing dependencies missing. Run: bash install-deps.sh --all"
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────
case "${1:-}" in
    --system)  install_system ;;
    --python)  install_python ;;
    --node)    install_node ;;
    --whisper) install_whisper ;;
    --check)   check_deps ;;
    --all)
        echo ""
        echo "==========================================="
        echo " Claude Code Toolkit - Dependencies"
        echo "==========================================="
        echo ""
        install_system
        echo ""
        install_python
        echo ""
        install_node
        echo ""
        echo -e "${YELLOW}[OPTIONAL]${NC} Audio/video transcription (faster-whisper, ~500MB):"
        echo "  Run: bash install-deps.sh --whisper"
        echo ""
        check_deps
        ;;
    *)
        echo "Usage: bash install-deps.sh [OPTION]"
        echo ""
        echo "Options:"
        echo "  --all      Install all dependencies (system + python + node)"
        echo "  --system   Install system packages only (apt/brew)"
        echo "  --python   Install Python packages only (pip)"
        echo "  --node     Install Node.js packages only (npm)"
        echo "  --whisper  Install faster-whisper for audio/video transcription (~500MB)"
        echo "  --check    Check which dependencies are installed"
        echo ""
        echo "Quick start:"
        echo "  bash install-deps.sh --all     # Install everything"
        echo "  bash install-deps.sh --check   # See what's missing"
        exit 1
        ;;
esac
