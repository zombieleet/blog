+++
title = 'Specification Pattern'
date = 2025-10-16T09:00:00+02:00
draft = false
tags = ['DDD', 'Specification Pattern', 'Software Architecture']
categories = ['Software Architecture', 'DDD']
+++

The Specification pattern combines business rules using boolean logic. It provides a way to encapsulate complex business logic into separate, reusable components that can be tested independently and combined flexibly.

## What Problem Does It Solve?

The Specification pattern tests whether objects meet specific requirements. In traditional approaches, business rules are often scattered throughout entities, services, or repositories, making them difficult to test, reuse, and modify. The Specification pattern centralizes these rules into dedicated classes.

## Key Benefits

Multiple specifications can be composed to express complex validation or decision logic while keeping domain objects clean and focused. This composition capability is one of the pattern's greatest strengths. You can build complex business rules by combining simple, single-purpose specifications.

The pattern prevents domain pollution by separating business rules from domain objects (entities, value objects, and aggregates). Your domain objects remain focused on their core responsibilities while specifications handle the validation and selection logic.

By encapsulating business rules, specifications become reusable across the domain. They can be combined using logical operators (`AND`, `OR`, `NOT`) instead of bloating entities and services with complex conditions. This approach makes your codebase more maintainable and your business rules more explicit.


## Core Components

A Specification is an interface with a single method `IsSatisfiedBy(anyObject)` that checks whether an object meets the specification's requirements. This simple interface is the foundation of the entire pattern.

Business rules are implemented as concrete classes that implement the Specification interface. Each specification class encapsulates a single business rule, making it easy to understand, test, and modify. The single responsibility principle is key here: each specification should check exactly one condition.

**Example: Loan Application Processing**

A fintech company processes thousands of loan applications daily. The business needs to automatically filter applications to identify those that qualify for approval.

The selection criteria are:
1. Applicant's credit score must be >= 700
2. Applicant's monthly income must be >= 3x the monthly loan repayment
3. Applicant has no active unpaid loans on the platform

These criteria are business rules that can be expressed as specifications and composed together to select qualifying applicants.

Without the specification pattern, our code would look like this:

```go
package main
import "fmt"

type LoanApplication struct {
    CreditScore int
    MonthlyIncome float64
    MonthlyRepayment float64
    ActiveLoans int
}


func main() {
    applications := []LoanApplication{
        {CreditScore: 750, MonthlyIncome: 6000, MonthlyRepayment: 1500, ActiveLoans: 0},
        {CreditScore: 680, MonthlyIncome: 4000, MonthlyRepayment: 2000, ActiveLoans: 1},
        {CreditScore: 720, MonthlyIncome: 3000, MonthlyRepayment: 900, ActiveLoans: 0},
    }

    var qualified []LoanApplication

    for _, app := range applications {
        if app.CreditScore >= 700 &&
            app.MonthlyIncome >= 3*app.MonthlyRepayment &&
            app.ActiveLoans == 0 {

            qualified = append(qualified, app)
        }
    }

    fmt.Printf("Qualified applicants: %d\n", len(qualified))
}
```
    
**Problems with this approach:**

1. **Tight coupling**: All rules are hardcoded inline within the loop. The business logic is mixed with the implementation details.

2. **Poor maintainability**: When rules change (e.g., adding "must have no criminal record"), you must modify this code block directly. This violates the open-closed principle.

3. **Code duplication**: To reuse these rules elsewhere (e.g., for pre-approval validation), you must duplicate the conditions. This leads to inconsistencies when rules need to be updated.

4. **Testing challenges**: Testing individual rules in isolation is difficult because everything is entangled. You cannot test the credit score rule without also testing the income and active loan rules.

5. **Lack of expressiveness**: The business rules are hidden in implementation details rather than being explicit domain concepts.
    
## Solution: Using the Specification Pattern

Here's the same logic using the Specification pattern. Notice how each business rule becomes a first-class citizen in the codebase:
{{< mermaidimg "specification-pattern-basic" >}}

```go
 package main

import "fmt"

type LoanApplication struct {
    CreditScore      int
    MonthlyIncome    float64
    MonthlyRepayment float64
    ActiveLoans      int
}

// Specification interface
type Specification interface {
    IsSatisfiedBy(app LoanApplication) bool
}

// CreditScoreSpec checks if credit score >= 700
type CreditScoreSpec struct{}

func (s CreditScoreSpec) IsSatisfiedBy(app LoanApplication) bool {
    return app.CreditScore >= 700
}

// IncomeSpec checks if monthly income >= 3x the loan repayment
type IncomeSpec struct{}

func (s IncomeSpec) IsSatisfiedBy(app LoanApplication) bool {
    return app.MonthlyIncome >= 3*app.MonthlyRepayment
}

// NoActiveLoanSpec checks if applicant has no active loans
type NoActiveLoanSpec struct{}

func (s NoActiveLoanSpec) IsSatisfiedBy(app LoanApplication) bool {
    return app.ActiveLoans == 0
}

// AndSpec composes two specs with logical AND
type AndSpec struct {
    left, right Specification
}

func (s AndSpec) IsSatisfiedBy(app LoanApplication) bool {
    return s.left.IsSatisfiedBy(app) && s.right.IsSatisfiedBy(app)
}

// Filter selects applications that satisfy the spec
func Filter(applications []LoanApplication, spec Specification) []LoanApplication {
    var selected []LoanApplication
    for _, a := range applications {
        if spec.IsSatisfiedBy(a) {
            selected = append(selected, a)
        }
    }
    return selected
}

func main() {
    applications := []LoanApplication{
        {CreditScore: 750, MonthlyIncome: 6000, MonthlyRepayment: 1500, ActiveLoans: 0},
        {CreditScore: 680, MonthlyIncome: 4000, MonthlyRepayment: 2000, ActiveLoans: 1},
        {CreditScore: 720, MonthlyIncome: 3000, MonthlyRepayment: 900, ActiveLoans: 0},
    }

    spec := AndSpec{
        left: CreditScoreSpec{},
        right: AndSpec{
            left:  IncomeSpec{},
            right: NoActiveLoanSpec{},
        },
    }

    qualified := Filter(applications, spec)
    fmt.Printf("Approved applicants: %d\n", len(qualified)) // -> Approved applicants: 2
}
```

## Combining Specifications with Other Patterns

The Specification pattern can be combined with a factory method to construct objects when business rules evaluate to true. This combination is particularly powerful because it separates the "what" (the business rules) from the "how" (the object construction).

In our loan application system, we can use the Factory pattern with specifications to create decision objects that inform clients of their approved credit limit. This approach keeps the decision logic separate from the business rules, making both easier to test and modify independently.

### Benefits of Factory-Specification Combination

1. **Separation of concerns**: Business rules remain in specifications while object creation logic stays in the factory
2. **Flexibility**: You can easily add new decision types without changing the specifications
3. **Testability**: Factory logic and specifications can be tested independently
4. **Extensibility**: New specifications can be added without modifying the factory

### Example: Business Requirement - Automated Loan Decisions

The business needs to provide immediate feedback to loan applicants about their application status. Instead of just filtering applications, the system must now:

1. Make a decision (approved or rejected) for each application
2. Provide a clear message explaining the decision
3. Set appropriate credit limits for approved applications

This requirement goes beyond simple filtering. We need to construct decision objects based on whether specifications are satisfied.

{{< mermaidimg "specification-pattern-factory" >}}

```go

type Factory struct{}

type Decision interface {
    Kind() string
    Message() string
}

type Approved struct{Limit float64}


func (Approved) Kind() string { return "APPROVED" }
func (a Approved) Message() string { return fmt.Sprintf("Approved up to %.2f", a.Limit) }

type Rejected struct{}
func (Rejected) Kind() string     { return "REJECTED" }
func (Rejected) Message() string  { return "Application does not meet policy" }

func (f Factory) Build(app LoanApplication, spec Specification) Decision {
    if spec.IsSatisfiedBy(app) {
        return Approved{Limit: 25000}
    }
    return Rejected{}
}


func main() {
    spec := AndSpec{
        left: CreditScoreSpec{},
        right: AndSpec{
            left: IncomeSpec{},
            right: NoActiveLoanSpec{},
        }
    }
    
    okLoanApplication := LoanApplication{CreditScore: 740, MonthlyIncome: 6000, MonthlyRepayment: 1500, ActiveLoans: 0}
    badLoanApplication := LoanApplication{CreditScore: 680, MonthlyIncome: 4000, MonthlyRepayment: 2000, ActiveLoans: 1}
    
    
    factory := Factory{}
    
    decisionOnOkLoan := factory.Build(okLoanApplication, spec)
    decisionOnBadLoan := factory.Build(badLoanApplication, spec)
    
    // APPROVED → Approved up to 25000.00
    fmt.Println(decisionOnOkLoan.Kind(), "=", decisionOnOkLoan.Message())
    // REJECTED → Application does not meet policy
    fmt.Println(decisionOnBadLoan.Kind(), "=", decisionOnBadLoan.Message())
}
```

## Three Main Uses of Specifications

The Specification pattern has three main uses:

### 1. Validation
Check if an object satisfies criteria. This is useful when you need to validate data before processing, such as checking if a loan application meets approval criteria before proceeding with underwriting.

### 2. Selection
Select all objects that satisfy criteria from a collection. This is commonly used in repository patterns where you need to filter entities based on business rules. For example, finding all loan applications that qualify for automatic approval.

### 3. Construction-to-order
Create objects based on satisfied criteria. This involves using specifications to determine what type of object to construct or how to configure it. Our Factory example demonstrates this by creating either an Approved or Rejected decision based on specification evaluation.

The same specification can be used for any of these purposes. The difference lies in how you apply it. A credit score specification can validate a single application, filter a list of applications, or determine which decision object to create.


## Advanced Composition Patterns

### Composing Multiple Specification Predicates

The real power of the Specification pattern emerges when you combine multiple specifications. This allows you to build complex business rules from simple, reusable components.

One of the most powerful features of the Specification pattern is the ability to combine simple specifications into complex ones using logical operators. This compositional approach mirrors how business stakeholders think about rules.

Consider these new business rules for a premium loan product:

1. **Financial Strength Rule**: An application is financially strong if the applicant has either:
   - Exceptional Credit: credit score ≥ 760
   - Strong Income Coverage: monthly income ≥ 3× the monthly repayment

2. **Eligibility Rule**: An application is eligible for approval if:
   - It is financially strong AND
   - The applicant has no active loans (active unpaid loans = 0)

Notice how these rules naturally compose. The eligibility rule builds upon the financial strength rule, which itself is a composition of two simpler rules. This hierarchical structure makes complex business logic more manageable.

```go
// ExceptionalCreditSpec checks if credit score >= 760
type ExceptionalCreditSpec struct{}

func (ExceptionalCreditSpec) IsSatisfiedBy(a LoanApplication) bool {
    return a.CreditScore >= 760
}

// StrongIncomeCoverageSpec checks if monthly income >= 3x the monthly repayment
type StrongIncomeCoverageSpec struct{}

func (StrongIncomeCoverageSpec) IsSatisfiedBy(a LoanApplication) bool {
    return a.MonthlyIncome >= 3*a.MonthlyRepayment
}

// HasActiveLoansSpec checks if applicant has any active loans
type HasActiveLoansSpec struct{}

func (HasActiveLoansSpec) IsSatisfiedBy(a LoanApplication) bool {
    return a.ActiveLoans > 0
}

type OrSpec struct {
    left, right Specification
}

func (s OrSpec) IsSatisfiedBy(app LoanApplication) bool {
    return s.left.IsSatisfiedBy(app) || s.right.IsSatisfiedBy(app)
}

type NotSpec struct {
    inner Specification
}

func (s NotSpec) IsSatisfiedBy(app LoanApplication) bool {
    return !s.inner.IsSatisfiedBy(app)
}

func main() {
    app := LoanApplication{CreditScore: 745, MonthlyIncome: 6000, MonthlyRepayment: 1800, ActiveLoans: 0}

    eligibleForApproval := AndSpec{
        left: OrSpec{
            left:  ExceptionalCreditSpec{},
            right: StrongIncomeCoverageSpec{},
        },
        right: NotSpec{
            inner: HasActiveLoansSpec{},
        },
    }
    // EligibleForApproval: true
    fmt.Println("EligibleForApproval:", eligibleForApproval.IsSatisfiedBy(app))
}
```

{{< mermaidimg "specification-pattern-composite" >}}



## When to Use the Specification Pattern

Consider using the Specification pattern when:

1. **Business rules change frequently**: If your domain has volatile business rules that need regular updates, specifications make these changes easier to manage.

2. **Rules need to be reused**: When the same business logic appears in multiple places (validation, querying, decision making), specifications eliminate duplication.

3. **Complex combinations are common**: If you frequently need to combine business rules in different ways, the composition capabilities of specifications are invaluable.

4. **Testing is important**: Specifications are inherently testable. Each rule can be tested in isolation, making your test suite more focused and maintainable.

5. **Domain complexity is high**: In complex domains with many interrelated rules, specifications help manage this complexity by breaking it into smaller, understandable pieces.

## Common Pitfalls to Avoid

1. **Over-engineering simple rules**: Not every condition needs to be a specification. Simple, stable checks can remain as regular methods.

2. **Creating too many specifications**: Group related rules logically. You don't need a separate specification for every tiny variation.

3. **Ignoring performance**: Complex specification trees can impact performance. Consider caching results or optimizing hot paths.

## Summary

The Specification pattern provides a flexible way to encapsulate business rules, making them testable, reusable, and composable. By separating business logic from domain objects, it helps maintain clean architecture and makes it easier to adapt to changing requirements.

The pattern shines in domains with complex, changing business rules that need to be applied in multiple contexts. While it adds some initial complexity, the benefits in maintainability, testability, and expressiveness often outweigh the costs in business-critical applications.

---

**Next Topic**: Specification Subsumption: exploring how specifications can be compared to determine if satisfying one specification automatically implies satisfying another.
