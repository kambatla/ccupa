# React / TypeScript Standards

Project-specific patterns for the React frontend. General React/TypeScript best practices are not repeated here.

## UI Components

- Use shared UI components (Button, Modal, Input, etc.) instead of raw HTML elements (`<button>`, `<input>`, `<select>`, `<textarea>`)
- Lint rules should enforce this where possible

## Design Tokens

Semantic Tailwind classes — no hardcoded colors:

```typescript
// Correct — semantic tokens
className="bg-action-primary text-text-inverse border-border-default"

// Wrong — hardcoded colors
className="bg-blue-500 text-white border-gray-300"
```

Use a utility like `cn()` or `clsx` for conditional classes.

## API Client

- One service class per domain, methods return typed promises
- API client handles auth tokens and 401 redirects automatically

## State Management

Context + Hook pattern:

```typescript
// contexts/FeatureContext.tsx
const FeatureContext = createContext<FeatureContextType | undefined>(undefined);

export const FeatureProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const value = useMemo(() => ({ ... }), [deps]);
  return <FeatureContext.Provider value={value}>{children}</FeatureContext.Provider>;
};

// hooks/useFeature.ts
export const useFeature = () => {
  const context = useContext(FeatureContext);
  if (context === undefined) {
    throw new Error("useFeature must be used within a FeatureProvider");
  }
  return context;
};
```

## File Organization

- Co-locate tests with source (`__tests__/` next to components)
- Group components by feature/domain
- Separate shared UI components from feature-specific ones
- Dedicated directories for hooks, contexts, types, and utilities

## Conventions

- Props interface: `{ComponentName}Props`
- Import order: React/framework → API/types → Hooks/utils → Components (blank lines between groups)
- `import type` for type-only imports

## Testing (Vitest + RTL)

- RTL query priority: ByRole > ByLabel > ByText > ByTestId
- `userEvent` over `fireEvent`
- Test files in `__tests__/` next to source
- Tests verify intended behavior, not implementation details. If a code change breaks a test, check whether the expected behavior has changed — if not, fix the implementation, don't update the test to match

## Tooling

- **ESLint** for linting
- **Prettier** for formatting
