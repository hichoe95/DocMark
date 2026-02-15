---
title: "Getting Started with DocMark"
description: "Learn how to use DocMark to read your project documentation"
difficulty: beginner
estimated_time: "5 minutes"
---

# Getting Started with DocMark

## Overview

DocMark is a Mac-native markdown documentation reader. It opens project folders, scans for `.md` files, and renders them beautifully.

## Opening a Project

1. Launch DocMark
2. Click **Open Folder** or press `Cmd+O`
3. Select your project folder
4. DocMark will scan all `.md` files and display them in the sidebar

## Navigation

### Sidebar
The sidebar shows your project's file tree. Click any file to view it.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+O` | Open folder |
| `Cmd+P` | Quick open |
| `Cmd+K` | Search |
| `Cmd+T` | Toggle Table of Contents |
| `Cmd+[` | Previous document |
| `Cmd+]` | Next document |
| `Shift+Cmd+L` | Project Library |

### Quick Open
Press `Cmd+P` to open the quick open panel. Start typing a filename to filter results.

### Search
Press `Cmd+K` to open the search panel. Search across all documents in the current project.

## Project Library

DocMark can manage multiple projects. Press `Shift+Cmd+L` to open the Project Library where you can:

- Switch between projects
- Mark favorites
- Pin important projects
- Filter by recent, favorites, or pinned

## Configuration

Create a `.docsconfig.yaml` file in your project root to define your documentation structure. This helps both DocMark and AI coding agents understand your docs.

See the [.docsconfig.yaml documentation](https://github.com/docmark/docmark) for the full schema.
