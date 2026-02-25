---
title: Contributing Guide
toc: true
---

Thank you for considering contributing to Linutil! We appreciate your effort in helping improve this project. Please follow these guidelines to make the contribution process smooth for everyone.

## 1. Install Rust

Make sure you have Rust installed on your machine:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Or visit [rust-lang.org](https://www.rust-lang.org/tools/install) for full instructions.

## 2. Fork and Clone the Repo

1. Fork the repository on GitHub
2. Clone your fork locally:

```bash
git clone https://github.com/YOUR_USERNAME/linutil.git
cd linutil
```

## 3. Make Your Changes

- Edit the relevant files
- Run `cargo run` to test your changes locally
- Ensure everything works as expected before submitting

## 4. Adding a New Script

If you're adding a new shell script:

1. Place it in the appropriate subdirectory under `tabs/`
2. Fill out **all fields** in `tab_data.toml` for your script
3. Run `cargo xtask docgen` to regenerate the documentation

Without completing `tab_data.toml` and running `docgen`, your script will not appear in the TUI or the documentation.

## 5. Understand the Existing Code

- **Have a clear reason**: Don't change the way things are done without a valid reason. Be prepared to explain why a change is necessary and how it improves the project.
- **Respect existing conventions**: Changes should align with the existing code style and project philosophy.

## 6. Learn from Past Pull Requests

- **Check merged PRs**: Reviewing accepted contributions gives you a sense of what is welcome.
- **Study rejected PRs**: This helps you avoid mistakes and proposals that have already been declined.

## 7. Write Clean Commit Messages

- Use the **imperative mood**: "Add feature X" not "Added feature X"
- Be descriptive about what changed and why
- Avoid committing a change and then immediately following it with a fix — amend or squash instead

## 8. Keep PRs Small and Focused

- One feature or fix per pull request
- Avoid combining unrelated changes in a single PR — it makes review harder and may delay merging

## 9. Test Your Code

- Review your code for readability and correctness before submitting
- Do not submit AI-generated code without thoroughly reviewing and testing it first
- Failure to test after multiple review requests may result in the PR being closed

## 10. Code Review

- All PRs go through code review — expect feedback and be open to revisions
- If you're comfortable, reviewing other contributors' PRs is a great way to give back

## 11. Contributing Beyond Code

- **Test the tool** across different distros and report issues
- **Write clear bug reports** with steps to reproduce, distro info, and error output
- **Propose reasonable feature requests** that fit the scope and style of the project
- **Improve documentation** to help other users

## 12. License

By contributing to Linutil, you agree that your contributions will be licensed under the project's [MIT License](https://github.com/ChrisTitusTech/linutil/blob/main/LICENSE).

---

We look forward to your contributions — thank you for helping make Linutil better for everyone!
