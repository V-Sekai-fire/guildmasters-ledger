# ADR Style Guide: Concise Format (< 30 Lines)

## Rule: Keep ADRs Under 30 Lines

### Purpose

ADRs should be concise and actionable. Long documents reduce readability and decision-making efficiency.

### Format Requirements

- **Maximum Length:** 30 lines total
- **Structure:** Standard ADR sections (Context, Decision, etc.) but condensed
- **Density:** Use paragraphs to combine related information
- **Clarity:** Maintain readability while maximizing information density

### Template Structure

```
# **R25WXXXXXX - Title**

**Status:** Proposed | **Date:** Month Day, Year

## **Context**
[1-2 sentence explanation of the problem/need]

## **Decision**
[Clear statement of the chosen approach]

## **Success Criteria**
[Measurable targets and decision framework]

## **Timeline**
[High-level schedule in paragraph form]

## **Next Steps**
[Numbered action items]
```

### Best Practices

1. **Combine Sections:** Merge related information (e.g., targets + go/no-go criteria)
2. **Use Paragraphs:** Convert bullet points to dense paragraphs when possible
3. **Eliminate Redundancy:** Remove duplicate explanations
4. **Focus on Essentials:** Include only decision-critical information
5. **Maintain Structure:** Keep standard ADR sections for consistency
6. **Include Concrete Examples:** When ADR title contains "syntax" or "specification", include concrete code examples in Next Steps

### Example Length Targets

- **Context:** 1-2 lines
- **Decision:** 1 line
- **Success Criteria:** 2-4 lines
- **Timeline:** 1-2 lines
- **Next Steps:** 4-6 lines

### Benefits

- **Faster Reading:** Decision-makers can scan quickly
- **Better Focus:** Eliminates unnecessary detail
- **Improved Decisions:** Clear, actionable information
- **Consistency:** Standardized format across all ADRs

### Enforcement

- **Line Count Check:** All new ADRs must be < 30 lines
- **Review Process:** ADR reviews should flag documents exceeding limit
- **Exceptions:** Require explicit approval for > 30 line ADRs
