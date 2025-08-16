# ComicCrawler User Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture Overview](#architecture-overview)
3. [Installation](#installation)
4. [Quick Start](#quick-start)
5. [Core Concepts](#core-concepts)
6. [Plugin System](#plugin-system)
7. [Object-Oriented Design](#object-oriented-design)
8. [Usage Guide](#usage-guide)
9. [Configuration](#configuration)
10. [Advanced Features](#advanced-features)
11. [Troubleshooting](#troubleshooting)
12. [Developer Guide](#developer-guide)
13. [API Reference](#api-reference)

## Overview

ComicCrawler is a sophisticated, extensible image crawling and downloading application designed with a modular architecture. It supports downloading images, comics, and other media from various websites through a plugin-based system. The application features both a command-line interface (CLI) and a graphical user interface (GUI) built with Tkinter.

### Key Features
- **Modular Plugin Architecture**: Extensible system for supporting new websites
- **Multi-threaded Downloads**: Concurrent downloading with configurable thread limits
- **Session Management**: Persistent sessions and cookie handling
- **Progress Tracking**: Real-time download progress and status monitoring
- **Cross-platform**: Works on Windows, macOS, and Linux
- **Multiple Output Formats**: Support for various image and archive formats

## Architecture Overview

ComicCrawler follows a well-structured, object-oriented design with clear separation of concerns:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GUI Layer     │    │  CLI Interface  │    │  Core Engine    │
│  (Tkinter)     │    │   (docopt)      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────────────────────────────────────┐
         │              Business Logic Layer               │
         │  ┌─────────────┐ ┌─────────────┐ ┌──────────┐  │
         │  │   Mission   │ │  Download   │ │ Analyzer │  │
         │  │  Manager    │ │  Manager    │ │          │  │
         │  └─────────────┘ └─────────────┘ └──────────┘  │
         └─────────────────────────────────────────────────┘
                                 │
         ┌─────────────────────────────────────────────────┐
         │              Plugin System                      │
         │  ┌─────────────┐ ┌─────────────┐ ┌──────────┐  │
         │  │   Pixiv     │ │   Twitter   │ │  Other   │  │
         │  │   Module    │ │   Module    │ │ Modules  │  │
         │  └─────────────┘ └─────────────┘ └──────────┘  │
         └─────────────────────────────────────────────────┘
                                 │
         ┌─────────────────────────────────────────────────┐
         │              Infrastructure Layer               │
         │  ┌─────────────┐ ┌─────────────┐ ┌──────────┐  │
         │  │   Grabber   │ │   Session   │ │   IO     │  │
         │  │             │ │  Manager    │ │          │  │
         │  └─────────────┘ └─────────────┘ └──────────┘  │
         └─────────────────────────────────────────────────┘
```

## Installation

### Prerequisites
- Python 3.10 or higher
- pip package manager

### Installation Methods

#### Method 1: From Source
```bash
git clone https://github.com/eight04/ComicCrawler.git
cd ComicCrawler
pip install -e .
```

#### Method 2: From PyPI
```bash
pip install comiccrawler
```

### Dependencies
The application automatically installs required dependencies:
- `belfrywidgets` - UI components
- `bidict` - Bidirectional dictionary
- `curl_cffi` - HTTP client with advanced features
- `desktop3` - Desktop integration
- `pythreadworker` - Threading utilities
- `urllib3` - HTTP library
- And many more (see `requirements.txt`)

## Quick Start

### Command Line Interface
```bash
# List supported websites
comiccrawler domains

# Download from a URL
comiccrawler download "https://example.com/comic" --dest "./downloads"

# Launch GUI
comiccrawler gui
```

### GUI Interface
1. Run `comiccrawler gui`
2. Click "Add Mission" to add a new download task
3. Enter the URL of the comic/image gallery
4. Click "Analyze" to scan for available content
5. Select episodes/pages to download
6. Click "Download" to start downloading

## Core Concepts

### Mission
A **Mission** represents a complete download task for a specific URL. It contains:
- **URL**: The source website address
- **Title**: Human-readable name for the mission
- **State**: Current status (ANALYZING, DOWNLOADING, FINISHED, ERROR)
- **Episodes**: List of downloadable content units
- **Module**: The plugin responsible for handling the website

### Episode
An **Episode** represents a single downloadable unit within a mission:
- **Title**: Name of the episode
- **URL**: Direct link to the episode
- **Current URL**: Current page being processed
- **Current Page**: Current page number
- **Total**: Total number of pages
- **Skip/Complete**: Download status flags

### Module
A **Module** is a plugin that handles a specific website or service:
- **Domain**: Website domains the module can handle
- **Name**: Human-readable module name
- **Configuration**: Module-specific settings
- **Methods**: Functions for title extraction, episode parsing, etc.

## Plugin System

ComicCrawler's plugin architecture is one of its most powerful features, allowing users to extend support to new websites without modifying the core application.

### Plugin Architecture

The plugin system follows a **dynamic loading pattern** with these key components:

#### 1. ModLoader Class
```python
class ModLoader:
    def __init__(self):
        self.mods = set()           # Set of loaded modules
        self.domain_index = {}      # Domain to module mapping
        self.loaded = False         # Loading state flag
```

**Responsibilities:**
- Discovers and loads plugin modules
- Builds domain-to-module mapping
- Manages module configuration
- Handles session setup for modules

#### 2. Plugin Discovery
```python
def load(self):
    # Load built-in modules
    for file in listdir(dirname(__file__)):
        if file.endswith('.py') and file != '__init__.py':
            self.mods.add(import_module("comiccrawler.mods." + name))
    
    # Load user modules
    user_mods_dir = profile("mods")
    if isdir(user_mods_dir):
        # Load custom modules from user directory
```

**Features:**
- **Built-in Modules**: Automatically loads from `comiccrawler/mods/`
- **User Modules**: Supports custom modules from user-defined directory
- **Hot Reloading**: Modules can be reloaded without restart

#### 3. Module Interface
Each plugin module must implement a standard interface:

```python
# Required attributes
domain = ["example.com", "www.example.com"]  # Supported domains
name = "Example Module"                      # Module name
config = {}                                  # Configuration options

# Required methods
def get_title(html, url):                   # Extract title from HTML
    pass

def get_episodes(html, url):                # Parse episodes from HTML
    pass

def get_images(html, url):                  # Extract image URLs
    pass
```

#### 4. Dynamic Module Resolution
```python
def get_module(self, url):
    """Return the downloader mod for specific URL or return None"""
    match = search(r"^https?://([^/]+?)(:\d+)?/", url)
    if not match:
        return None
        
    domain = match.group(1)
    
    # Try exact domain match first
    while domain:
        if domain in self.domain_index:
            return self.domain_index[domain]
        # Try parent domain (e.g., sub.example.com -> example.com)
        try:
            domain = domain[domain.index(".") + 1:]
        except ValueError:
            break
    return None
```

**Domain Matching Strategy:**
- **Exact Match**: Direct domain match
- **Parent Domain**: Falls back to parent domains
- **Hierarchical**: Supports subdomain resolution

### Plugin Configuration Management

#### 1. Configuration Inheritance
```python
# Module default configuration
config = {
    "cookie_session": "Enter your session cookie",
    "max_retries": 3,
    "delay": 1.0
}

# User configuration overrides
if mod.name not in config.config:
    mod.config = config.config["DEFAULT"]
else:
    mod.config = config.config[mod.name]
```

#### 2. Session Management
```python
def setup_session(mod):
    if getattr(mod, "autocurl", False):
        for key, value in mod.config.items():
            if key.startswith("curl") and value:
                session_manager.update_by_curl(value)
```

### Plugin Development Example

Here's a simplified example of how to create a custom plugin:

```python
# my_website.py
domain = ["mywebsite.com", "www.mywebsite.com"]
name = "My Website Module"
config = {
    "api_key": "Enter your API key",
    "download_delay": 2.0
}

def get_title(html, url):
    """Extract title from HTML"""
    import re
    match = re.search(r'<title>([^<]+)</title>', html)
    return match.group(1) if match else "Unknown Title"

def get_episodes(html, url):
    """Parse episodes from HTML"""
    from ..core import Episode
    episodes = []
    # Parse HTML to find episode links
    # Return list of Episode objects
    return episodes

def get_images(html, url):
    """Extract image URLs"""
    import re
    # Parse HTML to find image URLs
    # Return list of image URLs
    return image_urls
```

## Object-Oriented Design

ComicCrawler demonstrates excellent object-oriented design principles with clear separation of concerns and well-defined interfaces.

### Core Classes and Responsibilities

#### 1. Mission Management
```python
class MissionManager:
    """Thread-safe mission management with persistence"""
    
    def __init__(self):
        self.pool = {}           # All missions
        self.view = OrderedDict() # Missions in view
        self.library = OrderedDict() # Missions in library
        self.lock = Lock()       # Thread safety
```

**Design Patterns:**
- **Singleton Pattern**: Single instance manages all missions
- **Observer Pattern**: Notifies subscribers of mission changes
- **Thread Safety**: Lock-based synchronization

#### 2. Download Management
```python
class DownloadManager:
    """Manages concurrent downloads with thread pooling"""
    
    def __init__(self):
        self.crawlers = bidict[ModuleType, Worker]()
        self.max_threads = setting.getint("max_threads", 3)
        self.mod_errors = defaultdict(int)
```

**Design Patterns:**
- **Worker Pool Pattern**: Manages concurrent download threads
- **Bidirectional Mapping**: Links modules to worker threads
- **Error Tracking**: Monitors module-specific error rates

#### 3. Crawler Engine
```python
class Crawler:
    """Core crawling logic for individual episodes"""
    
    def __init__(self, mission, ep, savepath):
        self.mission = mission
        self.ep = episode
        self.savepath = SavePath(savepath, mission, ep)
        self.mod = mission.module
        self.downloader = ModuleGrabber(mission.module)
```

**Design Patterns:**
- **Strategy Pattern**: Different modules implement different crawling strategies
- **Factory Pattern**: Creates appropriate downloaders based on module
- **State Pattern**: Manages crawling state (init, downloading, finished)

#### 4. Episode Management
```python
class Episode:
    """Represents a single downloadable episode"""
    
    def __init__(self, title, url):
        self.title = title
        self.url = url
        self.current_url = None
        self.current_page = 1
        self.total = 0
        self.skip = False
        self.complete = False
```

**Design Patterns:**
- **Value Object**: Immutable episode data
- **Builder Pattern**: Episode construction through EpisodeList

### Design Principles Applied

#### 1. Single Responsibility Principle
Each class has a single, well-defined responsibility:
- `MissionManager`: Mission lifecycle management
- `DownloadManager`: Download orchestration
- `Crawler`: Individual download execution
- `Analyzer`: Content analysis and parsing

#### 2. Open/Closed Principle
The system is open for extension (new plugins) but closed for modification (core classes):
```python
# New modules can be added without changing core code
def get_module(self, url):
    # Dynamic module resolution
    return self.domain_index.get(domain)
```

#### 3. Dependency Inversion
High-level modules depend on abstractions, not concrete implementations:
```python
class Crawler:
    def __init__(self, mission, ep, savepath):
        self.mod = mission.module  # Abstract module interface
        self.downloader = ModuleGrabber(mission.module)  # Abstract downloader
```

#### 4. Interface Segregation
Modules implement only the methods they need:
```python
# Minimal interface requirements
def get_title(html, url): pass
def get_episodes(html, url): pass
def get_images(html, url): pass

# Optional methods
def after_request(self, response): pass
def session_key(url): pass
```

### Threading and Concurrency

#### 1. Worker Thread Management
```python
class DownloadManager:
    def start_download(self, mission):
        """Start download in separate thread"""
        if mission.module in self.crawlers:
            return
            
        worker = create_worker(download_worker, mission)
        self.crawlers[mission.module] = worker
```

#### 2. Thread-Safe Collections
```python
class ThreadSafeSet:
    def __init__(self):
        self.lock = Lock()
        self.obj = set()
        
    def add(self, item):
        with self.lock:
            return self.obj.add(item)
```

#### 3. Event-Driven Architecture
```python
# Channel-based communication between threads
@thread.listen("DOWNLOAD_ERROR")
def _(event):
    _err, mission = event.data
    mission_manager.drop("view", mission)
    self.mod_errors[mission.module] += 1
```

## Usage Guide

### Basic Operations

#### 1. Adding a New Mission
1. **GUI Method**:
   - Click "Add Mission" button
   - Enter the URL of the comic/gallery
   - Click "OK"

2. **CLI Method**:
   ```bash
   comiccrawler download "https://example.com/comic" --dest "./downloads"
   ```

#### 2. Mission Analysis
- **Purpose**: Scans the URL to discover available content
- **Process**: Downloads and parses HTML to extract episodes
- **Result**: Creates episode list with titles and URLs

#### 3. Episode Selection
- **Manual Selection**: Choose specific episodes to download
- **Bulk Operations**: Select all, select none, invert selection
- **Smart Selection**: Auto-select new or incomplete episodes

#### 4. Download Process
- **Concurrent Downloads**: Multiple episodes download simultaneously
- **Progress Tracking**: Real-time progress bars and status updates
- **Error Handling**: Automatic retry with exponential backoff
- **Resume Capability**: Can resume interrupted downloads

### Advanced Operations

#### 1. Batch Processing
```python
# Batch analyzer for multiple URLs
batch_analyzer = BatchAnalyzer(urls)
batch_analyzer.analyze_all()
```

#### 2. Library Management
- **Organize Missions**: Group related missions in library
- **Update Checking**: Automatic detection of new content
- **Archive Management**: Move completed missions to archive

#### 3. Custom Commands
```python
# Post-download commands
config = {
    "runafterdownload": "convert {file} {file}.jpg"
}
```

## Configuration

### Configuration Files

#### 1. Main Configuration (`config.ini`)
```ini
[DEFAULT]
max_threads = 3
save_path = ~/Downloads
runafterdownload = 
errorlog = true

[Pixiv]
cookie_PHPSESSID = your_session_id
originalfilename = false

[Twitter]
cookie_auth_token = your_auth_token
download_retweets = false
```

#### 2. Profile Configuration
- **Location**: `~/.comiccrawler/` (Linux/macOS) or `%USERPROFILE%\comiccrawler\` (Windows)
- **Files**:
  - `config.ini`: Application settings
  - `pool.json`: Mission data
  - `view.json`: View state
  - `library.json`: Library organization

### Environment Variables
```bash
export COMICCRAWLER_PROFILE="/custom/profile/path"
export COMICCRAWLER_CONFIG="/custom/config/path"
```

### Module-Specific Configuration

Each plugin module can define its own configuration options:

```python
# Example module configuration
config = {
    "cookie_session": "Session cookie value",
    "api_key": "API authentication key",
    "download_delay": 1.5,
    "max_retries": 3,
    "user_agent": "Custom User-Agent string"
}
```

## Advanced Features

### 1. Session Management
- **Cookie Persistence**: Maintains login sessions across restarts
- **Custom Headers**: Supports custom HTTP headers per module
- **Proxy Support**: Configurable HTTP/HTTPS proxies
- **Rate Limiting**: Built-in cooldown mechanisms

### 2. File Management
- **Smart Naming**: Configurable filename patterns
- **Directory Structure**: Automatic episode folder creation
- **File Validation**: Checksum verification for downloads
- **Format Conversion**: Post-download file processing

### 3. Error Handling
- **Graceful Degradation**: Continues operation despite individual failures
- **Retry Logic**: Exponential backoff for transient errors
- **Error Logging**: Detailed error tracking and reporting
- **Recovery Mechanisms**: Automatic cleanup and recovery

### 4. Performance Optimization
- **Connection Pooling**: Reuses HTTP connections
- **Compression Support**: Handles gzip/deflate compression
- **Caching**: Intelligent caching of parsed content
- **Memory Management**: Efficient memory usage for large downloads

## Troubleshooting

### Common Issues

#### 1. Module Not Found
**Problem**: Website not supported
**Solution**: Check if module exists in `comiccrawler/mods/` or create custom module

#### 2. Authentication Errors
**Problem**: Login required or expired
**Solution**: Update cookies in module configuration

#### 3. Download Failures
**Problem**: Network or server errors
**Solution**: Check network connection, retry, or adjust delay settings

#### 4. Performance Issues
**Problem**: Slow downloads or high resource usage
**Solution**: Adjust `max_threads`, enable compression, check network

### Debug Mode
```bash
# Enable debug logging
export COMICCRAWLER_DEBUG=1
comiccrawler gui
```

### Log Files
- **Application Log**: `~/.comiccrawler/comiccrawler.log`
- **Grabber Log**: `~/.comiccrawler/grabber.log`
- **Error Log**: `~/.comiccrawler/error.log`

## Developer Guide

### Creating Custom Modules

#### 1. Module Structure
```python
# my_module.py
domain = ["mywebsite.com"]
name = "My Website Module"
config = {
    "api_key": "Your API key",
    "download_delay": 1.0
}

def get_title(html, url):
    """Extract title from HTML"""
    pass

def get_episodes(html, url):
    """Parse episodes from HTML"""
    pass

def get_images(html, url):
    """Extract image URLs"""
    pass
```

#### 2. Required Methods
- **`get_title(html, url)`**: Extract human-readable title
- **`get_episodes(html, url)`**: Parse available episodes
- **`get_images(html, url)`**: Extract image URLs for current page

#### 3. Optional Methods
- **`after_request(self, response)`**: Post-request processing
- **`session_key(url)`**: Custom session management
- **`load_config()`**: Dynamic configuration loading

#### 4. Testing Your Module
```python
# Test module functionality
from comiccrawler.mods import get_module

module = get_module("https://mywebsite.com/comic")
if module:
    print(f"Module loaded: {module.name}")
else:
    print("Module not found")
```

### Extending Core Functionality

#### 1. Custom Downloaders
```python
class CustomDownloader(ModuleGrabber):
    def download_image(self, url, referer=None):
        # Custom download logic
        pass
```

#### 2. Custom Analyzers
```python
class CustomAnalyzer(Analyzer):
    def analyze_pages(self):
        # Custom analysis logic
        pass
```

#### 3. Custom Mission Types
```python
class CustomMission(Mission):
    def __init__(self, url, custom_param):
        super().__init__(url)
        self.custom_param = custom_param
```

## API Reference

### Core Classes

#### Mission
```python
class Mission:
    def __init__(self, url, title=None, episodes=None):
        self.url = url
        self.title = title
        self.episodes = episodes or []
        self.state = "NEW"
        self.module = None
```

#### Episode
```python
class Episode:
    def __init__(self, title, url):
        self.title = title
        self.url = url
        self.current_url = None
        self.current_page = 1
        self.total = 0
        self.skip = False
        self.complete = False
```

#### Crawler
```python
class Crawler:
    def __init__(self, mission, ep, savepath):
        self.mission = mission
        self.ep = ep
        self.savepath = SavePath(savepath, mission, ep)
        self.mod = mission.module
        self.downloader = ModuleGrabber(mission.module)
```

### Utility Functions

#### Module Management
```python
from comiccrawler.mods import list_domain, get_module, load_config

# List all supported domains
domains = list_domain()

# Get module for specific URL
module = get_module("https://example.com/comic")

# Reload module configurations
load_config()
```

#### Download Functions
```python
from comiccrawler.crawler import download
from comiccrawler.mission import Mission

# Create and download mission
mission = Mission(url="https://example.com/comic")
download(mission, savepath="./downloads")
```

### Configuration Management
```python
from comiccrawler.config import setting, config

# Access global settings
max_threads = setting.getint("max_threads", 3)

# Access module configuration
module_config = config.config["Pixiv"]
```

## Conclusion

ComicCrawler represents a well-architected, extensible solution for web content downloading. Its plugin-based architecture makes it easy to add support for new websites, while its object-oriented design ensures maintainability and extensibility.

The application demonstrates several key software engineering principles:
- **Modularity**: Clear separation of concerns
- **Extensibility**: Plugin system for new functionality
- **Thread Safety**: Robust concurrent processing
- **Error Handling**: Graceful degradation and recovery
- **Configuration Management**: Flexible settings system

Whether you're a user looking to download content or a developer wanting to extend functionality, ComicCrawler provides a solid foundation for web content management.

---

**Version**: 2025.3.24  
**License**: MIT  
**Author**: eight  
**Repository**: https://github.com/eight04/ComicCrawler