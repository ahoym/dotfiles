# Refactoring Patterns Reference

## Helper Class Extraction

When a class grows large, extract related logic into helper classes. This pattern applies to any object-oriented language.

**Why this matters:**
- **Single Responsibility Principle** - Each class has one reason to change
- **Separation of Concerns** - Distinct functionality lives in separate modules
- **Testability** - Extracted classes can be unit tested in isolation
- **Reusability** - Helpers can be used by other components

```
// Before: OrderProcessor mixes order processing with inventory tracking
class OrderProcessor {
    orders = []
    inventoryLevels = {}

    processOrder(order) { ... }
    checkInventory(item) { ... }
    updateInventory(item, quantity) { ... }
    reserveStock(item, quantity) { ... }
}

// After: InventoryManager encapsulates inventory concerns
class InventoryManager {
    levels = {}

    check(item) { ... }
    update(item, quantity) { ... }
    reserve(item, quantity) { ... }
}

class OrderProcessor {
    orders = []
    inventory = new InventoryManager()

    processOrder(order) { ... }
}
```

**Signs you need extraction:**
- A class has methods that only operate on a subset of its fields
- You find yourself prefixing method names (e.g., `inventory_check`, `inventory_update`)
- The class file is getting long and hard to navigate
- You want to test related functionality in isolation

## Helper Method Extraction

When code is duplicated across methods within a class, extract the common logic into a private helper method.

**Why this matters:**
- **DRY Principle** - Don't Repeat Yourself; changes only need to happen in one place
- **Readability** - Methods become shorter and more focused on their unique logic
- **Maintainability** - Bug fixes apply everywhere the helper is used

```
// Before: Duplicated object creation in run()
class BatchProcessor {
    run(split_pct) {
        train_processor = new DataProcessor(
            config=this.config,
            datasets=train_datasets,
            batch_size=this.batch_size,
            timeout=this.timeout,
            output_format=this.output_format,
            verbose=false,
        )
        test_processor = new DataProcessor(
            config=this.config,
            datasets=test_datasets,
            batch_size=this.batch_size,
            timeout=this.timeout,
            output_format=this.output_format,
            verbose=false,
        )
    }
}

// After: Extract helper method
class BatchProcessor {
    _create_processor(datasets, label) {
        return new DataProcessor(
            config=this.config,
            datasets=datasets,
            batch_size=this.batch_size,
            timeout=this.timeout,
            output_format=this.output_format,
            verbose=false,
        )
    }

    run(split_pct) {
        train_processor = this._create_processor(train_datasets, "training")
        test_processor = this._create_processor(test_datasets, "validation")
    }
}
```

**Signs you need method extraction:**
- The same code block appears in multiple methods
- You're copy-pasting code and changing only a few values
- A method is long because it includes setup/teardown that other methods also need

## Factory Functions

Use factory functions to reduce duplication when creating test objects. Provide sensible defaults so tests only specify the fields they care about.

**Why this matters:**
- **Reduces boilerplate** - Tests focus on what's being tested, not object construction
- **Centralizes defaults** - Change defaults in one place when requirements evolve
- **Improves readability** - Test intent is clearer when only relevant fields are specified

```
// Without factory: every test repeats all fields
order1 = new Order(id=1, customer="Alice", product="Widget", quantity=5, price=10.00, status="pending", ...)
order2 = new Order(id=2, customer="Bob", product="Widget", quantity=3, price=10.00, status="pending", ...)

// With factory: tests specify only what matters
function makeOrder(quantity, defaults...) {
    return new Order(
        id = generateId(),
        customer = "TestCustomer",
        product = "TestProduct",
        quantity = quantity,
        price = 10.00,
        status = "pending",
        ...defaults
    )
}

// Usage: makeOrder(quantity=5) or makeOrder(quantity=3, customer="VIP")
```

**When to use:**
- Test objects have many required fields
- Multiple tests create similar objects with small variations
- Object construction logic is complex (derived fields, validations)

## Nested Function Extraction (Python)

Do not define named functions inside other functions. Instead, define helper functions at module or class level.

**Why this matters:**
- **Testability** - Module-level functions can be unit tested directly
- **Reusability** - Other functions can use the helper
- **Readability** - Reduces nesting depth and cognitive load
- **Performance** - Avoids recreating function objects on each call

```python
# Before: nested function
def process_data(data):
    def format_value(v):
        return f"{v:.2f}"
    return [format_value(d) for d in data]

# After: helper at module level
def _format_value(v):
    return f"{v:.2f}"

def process_data(data):
    return [_format_value(d) for d in data]
```

**Signs you need extraction:**
- A `def` statement appears inside another `def`
- The inner function doesn't actually need variables from the enclosing scope
- You want to test the helper logic independently

**Exception:** Closures that genuinely need enclosing scope variables may remain nested, but consider if the state could be passed as parameters instead.

## Module to Package Extraction (Python)

When a single Python file grows too large (500+ lines), split it into a package with multiple focused modules while maintaining backwards compatibility.

**Why this matters:**
- **Navigability** - Smaller files are easier to understand and navigate
- **Single Responsibility** - Each module has one clear purpose
- **Testability** - Individual modules can be tested in isolation
- **Reduced merge conflicts** - Developers can work on separate modules

```python
# Before: monolithic module.py (1000+ lines)
module.py
├── Constants (lines 1-50)
├── DataClasses (lines 51-300)
├── Utility functions (lines 301-500)
├── Recommendations (lines 501-600)
└── Main class (lines 601-1000)

# After: package with focused modules
module/
├── __init__.py          # Re-exports public API
├── constants.py         # Constants and configuration
├── models.py            # Data classes and enums
├── utils.py             # Utility functions
├── recommendations.py   # Domain-specific logic
└── core.py              # Main class(es)
```

**Key steps:**
1. Create `module/` directory alongside `module.py`
2. Split code into logical submodules by responsibility
3. Create `__init__.py` that re-exports the public API:
   ```python
   # module/__init__.py
   from module.constants import CONSTANT_A, CONSTANT_B
   from module.models import ClassA, ClassB
   from module.core import MainClass

   __all__ = ["CONSTANT_A", "CONSTANT_B", "ClassA", "ClassB", "MainClass"]
   ```
4. Verify all tests pass with existing imports
5. Delete the original `module.py`

**Backwards compatibility:** Existing imports like `from module import X` continue working because Python treats a directory with `__init__.py` the same as a `.py` file.

**Signs you need extraction:**
- File exceeds 500-1000 lines
- File contains distinct sections (constants, models, utilities, main logic)
- Multiple developers frequently edit the same file
- You find yourself scrolling extensively to find code

**Naming conventions for submodules:**
- `constants.py` - Configuration values and magic numbers
- `models.py` or `types.py` - Data classes, enums, type definitions
- `utils.py` or `helpers.py` - Stateless utility functions
- `core.py` or named after the main class - Primary business logic
