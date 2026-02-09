# React / TypeScript Standards

Code patterns, conventions, and testing standards for the React frontend.

## Component Structure

```typescript
interface ComponentNameProps {
  requiredProp: string;
  optionalProp?: number;
  onAction?: (data: Type) => void;
}

const ComponentName: React.FC<ComponentNameProps> = ({
  requiredProp,
  optionalProp = defaultValue,
  onAction,
}) => {
  const [state, setState] = useState<Type>(initial);

  const handleAction = async () => {
    try {
      await operation();
      showSuccess("Done!");
    } catch (err: unknown) {
      showError(getErrorMessage(err));
    }
  };

  return (
    <div className={cn("base-classes", condition && "conditional")}>
      ...
    </div>
  );
};

export default ComponentName;
```

**Rules:**
- Props interface named `{ComponentName}Props`, defined above component
- `React.FC<Props>` for type annotation
- Destructure props with defaults
- `forwardRef` when ref forwarding is needed (add `displayName`)

## State Management

**Context + Hook pattern:**
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

## API Client

```typescript
// api/featureName.ts
import { apiClient } from "./client";

class FeatureService {
  async getItems(orgId: number): Promise<ItemResponse[]> {
    return apiClient.get<ItemResponse[]>(`/organizations/${orgId}/items`);
  }

  async createItem(data: CreateItemRequest): Promise<ItemResponse> {
    return apiClient.post<ItemResponse>("/items", data);
  }
}

export const featureService = new FeatureService();
```

**Rules:**
- One service class per domain
- Methods return typed promises
- `apiClient` handles auth tokens and 401 redirects automatically

## Error Handling

```typescript
// In async handlers
try {
  await operation();
  showSuccess("Operation completed!");
} catch (err: unknown) {
  showError(getErrorMessage(err));
}

// In data-loading effects
const [loading, setLoading] = useState(true);
const [error, setError] = useState("");

useEffect(() => {
  const load = async () => {
    try {
      const data = await apiCall();
      setState(data);
    } catch (err: unknown) {
      setError(getErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };
  load();
}, [deps]);
```

## UI Components

**Use shared components** from `components/ui/`:
- `Button`, `Modal`, `Alert`, `Card`, `Input`, `Select`, `Checkbox`, `Spinner`, `Badge`
- ESLint can enforce this — raw `<button>`, `<input>`, `<select>`, `<textarea>` are warnings

**Design tokens** via semantic Tailwind classes:
```typescript
// Correct — semantic tokens
className="bg-action-primary text-text-inverse border-border-default"

// Wrong — hardcoded colors
className="bg-blue-500 text-white border-gray-300"
```

**Conditional classes** via `cn()`:
```typescript
import { cn } from "../../utils/cn";

<div className={cn(
  "base-classes",
  isActive && "active-class",
  className,  // Allow parent override
)} />
```

## Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Component files | `PascalCase.tsx` | `OrderList.tsx` |
| Utility files | `camelCase.ts` | `formatDate.ts` |
| Hook files | `useCamelCase.ts` | `useOrganization.ts` |
| Test files | `Name.test.tsx` | `OrderList.test.tsx` |
| Components | `PascalCase` | `OrderList` |
| Functions/variables | `camelCase` | `handleSubmit` |
| Types/Interfaces | `PascalCase` | `OrderItem` |
| Props interfaces | `{Component}Props` | `OrderListProps` |

## File Organization

```
frontend/src/
├── api/                # Service classes (one per domain)
├── components/
│   ├── ui/             # Shared design system (Button, Modal, etc.)
│   ├── layout/         # App shell (NavigationBar, PageLayout)
│   └── {feature}/      # Feature: grouped by domain
│       └── __tests__/  # Tests next to source
├── contexts/           # React Context providers
├── hooks/              # Custom hooks
├── pages/              # Route-level page components
├── utils/              # Pure utility functions
└── types/              # Shared type definitions
```

## Cross-Cutting

### Import Order

Group imports with blank lines between groups:

```typescript
// 1. React & framework
import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";

// 2. API & types
import { apiClient } from "../../api";
import type { ResponseType } from "../../api";

// 3. Hooks & utils
import { useAuth } from "../../hooks/useAuth";
import { cn } from "../../utils/cn";

// 4. Components
import { Button, Modal } from "../ui";
```

Use `import type { ... }` for type-only imports.

### What NOT to Do

- **No `any` types** — use `unknown` and narrow, or define a proper type
- **No hardcoded colors** — use design tokens
- **No raw HTML form elements** — use UI components
- **No `console.log` in production code** — use `console.error` for actual errors only

---

## Testing Standards (Vitest + React Testing Library)

### Core Philosophy

**DO test:**
- User interactions (button clicks, form submissions, navigation)
- Business logic and data transformations
- API integration (request/response flows)
- Edge cases and error conditions
- Accessibility (screen reader support, keyboard navigation)

**DON'T test:**
- Third-party library internals
- Implementation details (internal state, private methods)
- Framework behavior
- Trivial getters/setters without logic

**Target: 80%+ coverage for new code.**

### Test Organization

```
src/
├── components/
│   ├── orders/
│   │   ├── OrderList.tsx
│   │   └── __tests__/
│   │       └── OrderList.test.tsx
├── hooks/
│   ├── useAuth.ts
│   └── __tests__/
│       └── useAuth.test.ts
└── utils/
    ├── formatDate.ts
    └── __tests__/
        └── formatDate.test.ts
```

**Rules:**
- `__tests__/` directory next to source files
- Test file mirrors source file name: `Component.tsx` -> `Component.test.tsx`
- One test file per component/hook/utility

### React Testing Library Principles

**Test user behavior, not implementation:**
```typescript
// GOOD: Test what user sees/does
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('user can submit login form', async () => {
  render(<LoginForm />);

  await userEvent.type(screen.getByLabelText(/email/i), 'user@example.com');
  await userEvent.type(screen.getByLabelText(/password/i), 'password123');
  await userEvent.click(screen.getByRole('button', { name: /log in/i }));

  expect(screen.getByText(/welcome/i)).toBeInTheDocument();
});

// BAD: Test implementation details
test('state updates on input change', () => {
  const { container } = render(<LoginForm />);
  const component = container.querySelector('.login-form');
  expect(component.state.email).toBe(''); // Don't access state!
});
```

**Query priority:**
1. `getByRole` (most accessible)
2. `getByLabelText` (form fields)
3. `getByText` (visible text)
4. `getByTestId` (last resort)

### Component Testing Patterns

**Basic component test:**
```typescript
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { OrderList } from '../OrderList';

describe('OrderList', () => {
  it('renders order items', () => {
    const orders = [{ id: 1, name: 'Widget', status: 'pending' }];
    render(<OrderList orders={orders} />);
    expect(screen.getByText('Widget')).toBeInTheDocument();
  });
});
```

**Test user interactions:**
```typescript
import userEvent from '@testing-library/user-event';

it('opens detail modal when row is clicked', async () => {
  const user = userEvent.setup();
  render(<OrderList orders={mockOrders} />);

  await user.click(screen.getByText('Widget'));

  expect(screen.getByRole('dialog')).toBeInTheDocument();
});
```

**Test accessibility:**
```typescript
it('has accessible button for adding item', () => {
  render(<OrderList orders={[]} />);

  const button = screen.getByRole('button', { name: /add item/i });
  expect(button).toBeInTheDocument();
  expect(button).not.toBeDisabled();
});

it('supports keyboard navigation', async () => {
  const user = userEvent.setup();
  render(<OrderForm />);

  await user.tab();
  expect(screen.getByLabelText(/name/i)).toHaveFocus();

  await user.tab();
  expect(screen.getByLabelText(/quantity/i)).toHaveFocus();
});
```

### Mocking Patterns

**Mock API calls with MSW (Mock Service Worker):**
```typescript
import { rest } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  rest.get('/api/items', (req, res, ctx) => {
    return res(ctx.json([
      { id: 1, name: 'Widget' },
      { id: 2, name: 'Gadget' }
    ]));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

it('displays item list', async () => {
  render(<ItemList />);
  expect(await screen.findByText('Widget')).toBeInTheDocument();
  expect(screen.getByText('Gadget')).toBeInTheDocument();
});
```

**Mock hooks and contexts:**
```typescript
import { vi } from 'vitest';

vi.mock('../../hooks/useAuth', () => ({
  useAuth: () => ({
    user: { id: '123', email: 'test@example.com' },
    isAuthenticated: true,
    logout: vi.fn()
  })
}));
```

**When to mock:**
- API calls (use MSW)
- External libraries (charts, date pickers)
- Browser APIs (localStorage, navigator)
- Context providers when testing isolated components

**When NOT to mock:**
- Component children (test integration)
- React hooks (test real behavior)
- Utility functions (test real implementation)

### Hook Testing

```typescript
import { renderHook, waitFor } from '@testing-library/react';
import { useItems } from '../useItems';

it('loads data on mount', async () => {
  const { result } = renderHook(() => useItems(1));

  await waitFor(() => {
    expect(result.current.isLoading).toBe(false);
  });

  expect(result.current.items).toBeDefined();
  expect(result.current.error).toBeNull();
});
```

### Error and Loading State Testing

```typescript
it('shows loading spinner while fetching', () => {
  render(<ItemList />);
  expect(screen.getByRole('progressbar')).toBeInTheDocument();
});

it('displays error message on API failure', async () => {
  server.use(
    rest.get('/api/items', (req, res, ctx) => {
      return res(ctx.status(500));
    })
  );

  render(<ItemList />);
  expect(await screen.findByText(/error loading/i)).toBeInTheDocument();
});

it('shows empty state when no items', async () => {
  server.use(
    rest.get('/api/items', (req, res, ctx) => {
      return res(ctx.json([]));
    })
  );

  render(<ItemList />);
  expect(await screen.findByText(/no items/i)).toBeInTheDocument();
});
```

### Common Pitfalls

**Don't query by class or ID:**
```typescript
// BAD
const button = container.querySelector('.submit-button');

// GOOD
const button = screen.getByRole('button', { name: /submit/i });
```

**Don't wait with arbitrary timeouts:**
```typescript
// BAD
await new Promise(resolve => setTimeout(resolve, 1000));

// GOOD
await waitFor(() => {
  expect(screen.getByText('Loaded')).toBeInTheDocument();
});
```

## Running Tests

```bash
cd frontend
npm test                                              # All tests
npm test -- src/components/__tests__/OrderList.test.tsx  # Specific file
npm run test:watch                                    # Watch mode
npm run test:coverage                                 # Coverage report
```

## Quick Reference

| Aspect | Standard |
|--------|----------|
| Coverage target | 80%+ |
| Test structure | Arrange-Act-Assert |
| Mock strategy | API calls (MSW), external libs |
| Naming | Same pattern as backend |
| Organization | `describe` blocks, `__tests__/` dirs |
| Queries | ByRole > ByLabel > ByText > ByTestId |
| User interaction | `userEvent` (not `fireEvent`) |
