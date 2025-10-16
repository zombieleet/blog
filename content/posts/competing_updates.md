+++
date = '2025-08-20T01:19:40+02:00'
draft = true
title = 'Competing Update Problem'
+++

The **competing update** (aka **lost update**) problem occurs when multiple operations modify the same record **without proper synchronization**, causing data to become inconsistent.

---

## Example: Joint Account on Two Nodes

Initial balances:

- **JohnDoeBankAccount** → $400  
- **JaneDoeBankAccount** → $100  
- **JakeBankAccount** → $200

`JohnDoeBankAccount` is a **joint account** owned by Alice and Bob; both are allowed to transfer money from it.

At the same time:

- **Node A (Alice):** transfer **$200** from John → Jane  
- **Node B (Bob):** transfer **$150** from John → Jake

To visualize the race:

{{< mermaidimg "competing-update-problem" >}}

---

## What Actually Happens

1. **Alice (Node A)** reads John’s balance → **$400**.  
2. **Bob (Node B)** reads John’s balance → **$400** (same snapshot).  
3. Alice updates John: $400 − $200 = **$200** (and credits Jane to **$300**).  
4. Bob, still believing John has $400, updates John: $400 − $150 = **$250** (and credits Jake to **$350**).  
5. Bob’s write **overwrites** Alice’s earlier write to John’s balance.

**Final stored balances (wrong):** John **$250**, Jane **$300**, Jake **$350**.  
**Correct serialized result should be:** $400 − $200 − $150 = **$50** (John **$50**, Jane **$300**, Jake **$350**).

---

## Why It Breaks

Both writers read the **same stale snapshot** and apply updates independently. Without coordination, the **second writer overwrites** the first—classic lost update.


---

## Avoiding Competing Updates

Since we cannot safely allow **all nodes** to write directly to the same shared resource, one common approach is to use a **leader–follower architecture**.  

In this model:

- A **single leader node** is responsible for handling all **write operations**.  
- Once a write is accepted and applied by the leader, it is **replicated (broadcast)** to all follower nodes.  
- Followers serve **read requests**, but only the leader mutates state.  

This ensures that updates are applied in a **single, serialized order**, preventing the lost update problem in distributed systems.

---

## How This Solution Works

Assume **Node B acts as the leader**.  
When Alice issues a transfer request through **Node A**, that request is simply **forwarded to Node B**.  

Now both Alice’s and Bob’s updates reach the same leader.  
Since **only the leader can write**, Node B applies the operations **one after the other**:

1. Deduct $200 from John and credit Jane.  
2. Deduct $150 from the updated John balance and credit Jake.  

By processing requests in a **single, consistent order**, the leader prevents the lost update problem.  
The final balances are correct: John $50, Jane $300, Jake $350.

This is a visual representation of what it would look like

{{< mermaidimg "competing-update-solution-simple-leader-follower-solution" >}}
