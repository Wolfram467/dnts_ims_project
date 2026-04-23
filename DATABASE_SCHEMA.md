# Database Schema: DNTS_IMS

## Overview
This document defines the PostgreSQL database schema for the DNTS Inventory Management System. The architecture accounts for strict lab-based location assignments, tracking of temporary deployments (borrowed items), and a split between serialized hardware and bulk consumables.

## Enums (Custom Data Types)
* `user_role`: `['dnts_head', 'lab_ta', 'viewer']`
* `hardware_category`: `['Monitor', 'Mouse', 'Keyboard', 'System Unit', 'AVR', 'SSD']`
* `asset_status`: `['Deployed', 'Borrowed', 'Under Maintenance', 'Storage', 'Retired']`

---

## Tables

### 1. `profiles`
Manages system access. New users default to a 'viewer' role but cannot view data until `is_approved` is true.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Foreign Key to `auth.users.id` |
| `full_name` | `text` | Not Null |
| `role` | `user_role` | Default: 'viewer' |
| `is_approved` | `boolean` | Default: false (DNTS Head must approve) |
| `assigned_lab` | `text` | Nullable (e.g., 'Lab 6') |

### 2. `locations`
Defines the valid areas an item can exist. Includes the 7 labs, the 'Others' storage, and external borrowing entities.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Default: `uuid_generate_v4()` |
| `name` | `text` | Not Null, Unique (e.g., 'LAB 1', 'Others', 'Registrar') |
| `is_lab` | `boolean` | Default: true (False for 'Others' and borrowing entities) |

### 3. `serialized_assets` (Hardware Inventory)
Tracks individual PC components. Enforces the DNTS naming convention and tracks wandering items.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Default: `uuid_generate_v4()` |
| `dnts_serial` | `text` | Not Null, Unique. Format Rule: `CT1_LAB#_[MR|M|K|SU|AVR|SSD]#` |
| `mfg_serial` | `text` | Not Null, Unique (Manufacturer Serial Number) |
| `category` | `hardware_category`| Not Null |
| `designated_lab_id`| `uuid` | Foreign Key to `locations.id`. Where the item *belongs*. |
| `current_loc_id` | `uuid` | Foreign Key to `locations.id`. Where the item *actually is*. |
| `status` | `asset_status` | Default: 'Storage' |
| `notes` | `text` | Nullable |

### 4. `bulk_consumables` (The "Others" Inventory)
Simplified tracking for non-serialized items.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Default: `uuid_generate_v4()` |
| `item_name` | `text` | Not Null (e.g., 'RJ45 Connectors') |
| `quantity` | `integer` | Default: 0 |
| `minimum_stock` | `integer` | Threshold for re-order alerts |

### 5. `movement_logs` (Audit & Borrowing Ledger)
Tracks every status change, lab transfer, or borrowing event. Crucial for generating Property Custodian reports.

| Column Name | Data Type | Constraints / Notes |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key, Default: `uuid_generate_v4()` |
| `asset_id` | `uuid` | Foreign Key to `serialized_assets.id` |
| `action_by` | `uuid` | Foreign Key to `profiles.id` (The TA/Head who logged it) |
| `previous_loc_id`| `uuid` | Foreign Key to `locations.id` |
| `new_loc_id` | `uuid` | Foreign Key to `locations.id` |
| `status_change` | `text` | e.g., 'Deployed -> Borrowed' |
| `borrower_name` | `text` | Nullable (e.g., 'Registrar Office') |
| `created_at` | `timestamptz` | Default: `now()` |

---

## Row Level Security (RLS) Directives
All tables MUST have RLS enabled. The AI should generate policies based on these strict rules:
1. **Admin Power:** Users where `role` in `('dnts_head', 'lab_ta')` have FULL access (SELECT, INSERT, UPDATE, DELETE) to `assets`, `locations`, and `consumables`. 
2. **Viewer Power:** Users where `role = 'viewer'` AND `is_approved = true` have READ-ONLY access (SELECT). If `is_approved = false`, they cannot see any data.
3. **User Management:** ONLY users with the `dnts_head` role can update the `profiles` table to change a user's `is_approved` status or `role`.
4. **Audit Immutability:** `movement_logs` are insert-only. No role can UPDATE or DELETE a log.