# Custom Instructions

## Purpose
These instructions guide GitHub Copilot's behavior when assisting with code generation, editing, and maintenance within this repository. The goal is to maintain high-quality, secure, and stylistically consistent code while supporting organized development practices.

---

## Core Development Rules

### 1. Changelog Management
- After completing any group of changes, **append an entry to `changelog.md`** located in the root directory.
- If `changelog.md` does not exist, **create it**.
- Each changelog entry must follow this format:
  ```
  ### Update [# + last update number + 1]: [name for update]
  ---
  - Change 1: [description of change]
  - Reasoning 1: [reason for making change]
  ---
  - Change 2: [description of change]
  - Reasoning 2: [reason for making change]
  ---
  ###### Files affected:
     [list of files changed by this update]
  ```

### 2. Framework Usage
- Use the **latest stable version of the Flutter framework** for all frontend code.
- Use the **latest stable version of Firebase** for backend or cloud functionality.
- Regularly check for updates to both frameworks and migrate code as necessary.

### 3. Firebase Architecture Assumptions
- **Do not assume** the implementation details of a Firebase project.
- If any **non-trivial information** is required about the **Firebase architecture**, configuration, or security rules that is **not explicitly present in the codebase**, **prompt the user** for the necessary data or documentation before proceeding.

### 4. External Setup and Configuration
- If any **setup, installation, or configuration steps** are required that **extend beyond the codebase** (e.g., Firebase project setup, authentication configuration, deployment settings):
- **Do not attempt to execute or assume these steps automatically.**
- **Provide clear and detailed instructions** for the user to follow manually.
- Wait for confirmation or required input before continuing any dependent code generation.

### 5. Coding Standards
- Follow **Flutter’s official style guide** for code formatting and structure.
- Adhere to **best practices** for Dart and Firebase development.
- Avoid deprecated flutter, dart, and/or firebase method calls. Review latest documention to see how to replace deprecated method calls.
- Avoid using 'BuildContext's across async gaps by capturing current context in a variable before entering async codeblocks.
- Ensure code is **modular** with a clear separation of concerns for improved maintainability and readability.

### 6. Code Documentation
- Include **clear, concise comments** explaining the functionality of any non-trivial or complex code blocks.
- Use docstrings or inline comments where necessary for context or rationale.

### 7. Security Practices
- Ensure all code is **secure by design**:
  - Sanitize all user inputs.
  - Validate and authenticate requests properly.
  - Avoid common vulnerabilities (e.g., XSS, SQL injection, insecure storage).
  - Stay current with CVE (Common Vulnerabilities and Exposures) notices relevant to Flutter and Firebase.

### 8. UI/UX Design Guidelines
- Apply **neo-brutalist design principles** to frontend UI components:
  - Use bold lines, flat colors, minimal gradients.
  - Prioritize legibility, spacing, and raw or intentionally “incomplete” aesthetics.
  - Avoid excessive polish in favor of functionally direct and expressive interfaces.

---

## Notes
- These instructions are continuously applicable and must be followed for all commits, branches, and pull requests.
- Copilot should infer context and apply these rules dynamically to any new or edited files in the project.