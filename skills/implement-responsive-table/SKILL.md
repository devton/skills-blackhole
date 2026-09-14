---
name: implement-responsive-table
description: Executable contract to build premium responsive tables with memoized search, multi-selection filters, animated sorting, empty states, and skeleton loaders in React.
metadata:
  author: Blackhole Team
  version: "1.0"
  tags: react, tailwindcss, design-system, typescript, tables, ux
---

# Shared Skill: Implement Responsive Table Pattern

This skill serves as a premium, non-negotiable contract to build and refactor data tables in React/Next.js applications. It ensures all tables achieve state-of-the-art visual excellence, high-performance interactions, and perfect mobile responsiveness.

---

## 🎯 Goal & Overview

To create robust, accessible, and highly-performant table interfaces that remain fully responsive across all device sizes, incorporating built-in local search, custom multi-select filtering, column sorting, and smooth UX states (Loading, Empty, and Search Zero-matches).

---

## 🏛️ Invariants & Rules

Every table built under this contract MUST strictly enforce the following rules:

1. **Semantic HTML Components Only**: Never use pure HTML `<table>` tags. Always use the design system's wrappers (`<Table>`, `<TableHeader>`, `<TableBody>`, `<TableRow>`, `<TableHead>`, `<TableCell>`).
2. **Horizontal Scroll Wrapper**: The outer container of the table must always be wrapped in a scrollable block (`relative w-full overflow-auto`) to guarantee that the UI never breaks or pushes layout elements on ultra-small screens.
3. **Mobile-First Inverted Breakpoints**: Hide non-essential secondary columns on mobile screens and explicitly show them using the inverted breakpoint syntax (e.g., `hidden min-md:table-cell`).
4. **Local Search Memoization**: Large dataset filtering must be memoized using `useMemo` combined with a robust case-insensitive `matchesQuery` pattern.
5. **No Double Memos**: Avoid unnecessarily wrapping simple lightweight operations in `useMemo` if datasets are static and small (< 50 items).
6. **Animated Sort Chevron Indicators**: Header cells that support sorting must be interactive, showing a subtle chevron icon that rotates gracefully (e.g., `rotate-180` for descending direction) with transition utility classes (`transition-transform duration-200`).
7. **Three-Phase State Management**: All tables must explicitly handle:
    - **Loading Phase**: Alignment-matching skeleton rows.
    - **Total Empty Phase**: A centered layout card with an empty illustration.
    - **Search Zero-Matches Phase**: A single row containing a full `colSpan` cell indicating no matching results for the current query.

---

## 🛠️ Inputs & Context

When invoking this workflow, define these input options:

```json
{
  "columns": [
    { "key": "name", "label": "Name", "sortable": true, "responsive": "always" },
    { "key": "email", "label": "Email", "sortable": true, "responsive": "min-md:table-cell" },
    { "key": "role", "label": "Role", "sortable": false, "responsive": "min-lg:table-cell" }
  ],
  "searchFields": ["name", "email"],
  "pageSize": 10
}
```

---

## 🔄 Deterministic Step-by-Step Procedure

### Step 1: Setup the Layout Container
Wrap the entire component in a standard structural block. Place the search/filter toolbar at the top and the table scrollable wrapper directly below it.

```tsx
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";

export function DataList({ data }) {
  return (
    <div className="w-full space-y-4">
      {/* Step 3: Toolbar goes here */}
      
      {/* Table Scrollable Wrapper */}
      <div className="relative w-full overflow-auto rounded-lg border border-neutral-200 dark:border-neutral-800">
        <Table>
          {/* Table contents */}
        </Table>
      </div>
    </div>
  );
}
```

### Step 2: Implement Responsive Column Mapping
Apply the `responsive` visibility classes to the corresponding `<TableHead>` and `<TableCell>` components to hide them gracefully on smaller viewports.

```tsx
<TableHeader>
  <TableRow>
    <TableHead className="table-cell">Name</TableHead>
    <TableHead className="hidden min-md:table-cell">Email</TableHead>
    <TableHead className="hidden min-lg:table-cell text-right">Role</TableHead>
  </TableRow>
</TableHeader>

<TableBody>
  {processedData.map((item) => (
    <TableRow key={item.id}>
      <TableCell className="table-cell font-medium">{item.name}</TableCell>
      <TableCell className="hidden min-md:table-cell">{item.email}</TableCell>
      <TableCell className="hidden min-lg:table-cell text-right">{item.role}</TableCell>
    </TableRow>
  ))}
</TableBody>
```

### Step 3: Integrate Memoized Search and Local Filter Logic
Create a search query state, and memoize the data filtering process with a robust utility.

```tsx
import { useState, useMemo } from "react";

// Safe text search matcher utility
export function matchesQuery(value: any, query: string): boolean {
  if (value === null || value === undefined) return false;
  return String(value).toLowerCase().includes(query.toLowerCase());
}

// Inside the component:
const [searchQuery, setSearchQuery] = useState("");

const filteredData = useMemo(() => {
  if (!searchQuery.trim()) return data;
  
  return data.filter((item) =>
    searchFields.some((field) => matchesQuery(item[field], searchQuery))
  );
}, [data, searchQuery]);
```

### Step 4: Implement Interactive Column Sorting
Manage sorting state and apply the sorter process immediately after the search memo.

```tsx
const [sortConfig, setSortConfig] = useState<{ key: string; direction: "asc" | "desc" } | null>(null);

const sortedData = useMemo(() => {
  const sortableData = [...filteredData];
  if (!sortConfig) return sortableData;

  return sortableData.sort((a, b) => {
    const aValue = a[sortConfig.key];
    const bValue = b[sortConfig.key];

    if (aValue === bValue) return 0;
    if (aValue < bValue) return sortConfig.direction === "asc" ? -1 : 1;
    return sortConfig.direction === "asc" ? 1 : -1;
  });
}, [filteredData, sortConfig]);

const handleSort = (key: string) => {
  let direction: "asc" | "desc" = "asc";
  if (sortConfig && sortConfig.key === key && sortConfig.direction === "asc") {
    direction = "desc";
  }
  setSortConfig({ key, direction });
};
```

Update header cells with interactive triggers and Chevron rotation indicators:

```tsx
import { ChevronDown } from "lucide-react";

<TableHead 
  className="cursor-pointer select-none hover:bg-neutral-50 dark:hover:bg-neutral-900 transition-colors"
  onClick={() => handleSort("name")}
>
  <div className="flex items-center gap-1">
    <span>Name</span>
    {sortConfig?.key === "name" && (
      <ChevronDown 
        className={`w-4 h-4 text-neutral-500 transition-transform duration-200 ${
          sortConfig.direction === "desc" ? "rotate-180" : ""
        }`} 
      />
    )}
  </div>
</TableHead>
```

### Step 5: Master UI States (Loading, Empty, Zero-matches)

#### A. Skeleton Loading
Use an explicit loader layout matching column structures during loading states.

```tsx
if (isLoading) {
  return (
    <TableBody>
      {Array.from({ length: 5 }).map((_, rowIndex) => (
        <TableRow key={rowIndex}>
          <TableCell><div className="h-5 w-32 bg-neutral-200 dark:bg-neutral-800 animate-pulse rounded" /></TableCell>
          <TableCell className="hidden min-md:table-cell"><div className="h-5 w-48 bg-neutral-200 dark:bg-neutral-800 animate-pulse rounded" /></TableCell>
          <TableCell className="hidden min-lg:table-cell text-right"><div className="h-5 w-24 ml-auto bg-neutral-200 dark:bg-neutral-800 animate-pulse rounded" /></TableCell>
        </TableRow>
      ))}
    </TableBody>
  );
}
```

#### B. Total Empty State
Show a premium callout card if the primary data array is empty.

```tsx
if (data.length === 0) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center rounded-lg border border-dashed border-neutral-300 dark:border-neutral-700">
      <div className="p-3 bg-neutral-100 dark:bg-neutral-900 rounded-full mb-3 text-neutral-400">
        <InboxIcon className="w-6 h-6" />
      </div>
      <h3 className="font-semibold text-neutral-900 dark:text-neutral-100">No records found</h3>
      <p className="text-sm text-neutral-500 max-w-sm mt-1">Get started by creating your very first record using the action above.</p>
    </div>
  );
}
```

#### C. Search Zero-Matches State
Show a spanned table cell alert when local query results return empty.

```tsx
if (sortedData.length === 0) {
  return (
    <TableBody>
      <TableRow>
        <TableCell colSpan={3} className="h-32 text-center text-neutral-500">
          <div className="flex flex-col items-center justify-center gap-1">
            <span className="font-medium text-neutral-900 dark:text-neutral-100">No results match your search</span>
            <span className="text-sm text-neutral-400">Try adjusting your keywords or clearing the query field.</span>
          </div>
        </TableCell>
      </TableRow>
    </TableBody>
  );
}
```

---

## 🏁 Quality & Review Gate

Before concluding any table implementation, perform this self-audit checklist:

*   [ ] **Scroll Container**: Does the table have a parent div container configured with `relative w-full overflow-auto`?
*   [ ] **Tailwind Inverted Breakpoints**: Are secondary columns hidden on mobile using `hidden min-md:table-cell` patterns?
*   [ ] **Query Memoization**: Is the filter query memoized using `useMemo` with local safety bounds?
*   [ ] **Search State Handler**: If the search returns 0 items, does it render the single full-width cell `TableRow` instead of just an empty page?
*   [ ] **Sort Indicator**: Do sort headers toggle state cleanly, and does the Chevron rotate smoothly using CSS transitions?
*   [ ] **Typography & Colors**: Do header labels use subtle colors (neutral-500/dark:neutral-400) and cell contents use appropriate font weights?
