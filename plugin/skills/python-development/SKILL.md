---
name: python-development
description: Use for Python applications, libraries, APIs, automation, packaging, typing and testing.
---
# Python development
- Inspect Python version, virtual environment, dependency manager, project layout and existing style first. Check for a local `.venv\Scripts\python.exe` before running scripts so global environments are not scanned; test with `pytest` or `python -m unittest`.
- Use type hints and clear interfaces consistent with the project; avoid unnecessary abstractions.
- Use context managers for resources and handle exceptions specifically.
- Use async only when supported by the execution model and beneficial for I/O concurrency.
- Follow existing FastAPI, Django, Flask or CLI conventions rather than introducing a new framework.
- Use the existing test suite; consider pytest, Ruff and mypy when already configured.
- Avoid unnecessary dependencies and check compatibility/security before upgrades.
