# AGENTS.md - ZMK Config Guidelines

## Build Commands
- **Full build**: Push to GitHub (uses zmkfirmware/zmk workflow)

## Test Commands
- **No traditional tests**: ZMK configs don't have unit tests
- **Validation**: Build succeeds without errors
- **Hardware test**: Flash and test keymap functionality

## Code Style Guidelines

### File Organization
- Keep config files in `config/` directory
- Board-specific configs in `config/boards/shields/[shield]/`
- Use descriptive filenames with snake_case

### DTS/DTSI Syntax
- Use C-style comments: `/* comment */`
- Node names in snake_case: `combo_accent_layer`
- Properties use kebab-case: `key-positions`
- Align assignments with proper indentation
- Include required headers: `<behaviors.dtsi>`, `<dt-bindings/zmk/keys.h>`

### Keymap Structure
- Group related functionality (combos, macros, behaviors)
- Use consistent spacing in bindings arrays
- Document complex macros with comments
- Follow layer naming conventions (base, numbers, symbols, etc.)

### Error Handling
- Validate all key positions exist in hardware
- Ensure binding compatibility
- Check for conflicting key assignments

### Naming Conventions
- snake_case for all identifiers
- Prefix macros/behaviors with descriptive names
- Use consistent layer indices across similar configs</content>
<parameter name="filePath">/home/thecrawler/zmk-config/AGENTS.md
