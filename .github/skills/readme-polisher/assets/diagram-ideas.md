# Mermaid Diagram Starters

Only use a diagram when the repository has multiple meaningful pieces. Rename the nodes to match the actual project.

## Web App + API

```mermaid
flowchart LR
    User[User] --> Web[Frontend]
    Web --> Api[Backend API]
    Api --> Db[(Database)]
```

## CLI Tool

```mermaid
flowchart LR
    Input[Command Input] --> Parser[Argument Parser]
    Parser --> Action[Command Handler]
    Action --> Output[Console Output]
    Action --> Files[File System]
```

## Package Workspace

```mermaid
flowchart TD
    Root[Workspace Root] --> Core[packages/core]
    Root --> App[apps/web]
    Root --> Cli[packages/cli]
    App --> Core
    Cli --> Core
```

## Content Pipeline

```mermaid
flowchart LR
    Source[Source Files] --> Build[Transform / Build]
    Build --> Site[Generated Output]
    Site --> Deploy[Deployment]
```
