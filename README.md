# 🧾 SAP ABAP — Custom Sales Order ALV Report

**Capstone Project | KIIT | SAP ABAP Developer Track (C_ABAPD)**

---

## 📌 Project Overview

This project implements a **Custom Sales Order ALV Report** in SAP ABAP that provides a real-time, interactive view of all Sales Orders with customer details, material information, order values, and processing status.

The report is built using the standard SAP `REUSE_ALV_GRID_DISPLAY` function module and follows best practices for ABAP development including modular programming, performance-optimized database access, and user-friendly ALV features.

---

## 🎯 Problem Statement

In large organizations, the standard SAP Sales Order reports (e.g., VA05) lack flexibility — they cannot combine header + item + status data in one view, cannot be easily customized, and do not support drill-down to the order level. Business users need a single, consolidated report that shows:

- Which Sales Orders are open, in-process, or completed
- Customer-wise order value summaries
- Material-level order details
- Quick navigation to the actual order (VA03)

---

## 💡 Solution Features

| Feature | Description |
|---|---|
| 🔍 **Selection Screen** | Filter by Sales Org, Customer, Date Range, Doc Type, Status |
| 📊 **ALV Grid Display** | Interactive, sortable, filterable grid output |
| 🚦 **Traffic Lights** | Visual status indicator (Green/Yellow/Red) per order |
| ➕ **Subtotals** | Automatic subtotals by Sales Org and Customer |
| 💰 **Grand Total** | Total Net Value across all displayed orders |
| 🖱️ **Double-Click Drill-Down** | Click any row to open the Sales Order in VA03 |
| 💾 **Layout Variants** | Save and reuse custom column layouts |
| 🖨️ **Top-of-Page Header** | Report title, selection info, run-by details |

---

## 🗂️ Project Structure

```
sap-alv-sales-report/
│
├── src/
│   └── ZSO_ALV_REPORT.abap       ← Main ABAP Program
│
├── docs/
│   └── SAP_ALV_Project_Documentation.pdf   ← Full Project Documentation
│
└── README.md                      ← This file
```

---

## ⚙️ Tech Stack

| Component | Details |
|---|---|
| Language | ABAP (Advanced Business Application Programming) |
| SAP Module | SAP SD (Sales & Distribution) |
| ALV Function | `REUSE_ALV_GRID_DISPLAY` |
| DB Tables Used | VBAK, VBAP, KNA1, VBUK |
| Transaction | ZSO_ALV (Custom) |
| SAP System | SAP ECC 6.0 / S/4HANA compatible |
| Certification Track | C_ABAPD — SAP Certified Associate Back-End Developer ABAP Cloud |

---

## 🗄️ Database Tables Used

| Table | Description |
|---|---|
| `VBAK` | Sales Order Header |
| `VBAP` | Sales Order Items |
| `KNA1` | Customer Master (General) |
| `VBUK` | Sales Document Status (Header) |

---

## 🔄 Program Flow

```
START-OF-SELECTION
        │
        ▼
  FETCH_DATA (FORM)
  ├── SELECT from VBAK + KNA1  → Header data
  ├── SELECT from VBAP         → Item data
  └── SELECT from VBUK         → Status data
        │
        ▼
  PROCESS_DATA (FORM)
  └── Assign traffic lights based on GBSTA status
        │
        ▼
  DISPLAY_ALV (FORM)
  ├── BUILD_FIELDCAT  → Define columns
  ├── BUILD_LAYOUT    → ALV layout settings
  ├── BUILD_SORT      → Sorting + Subtotals
  └── REUSE_ALV_GRID_DISPLAY → Render output
        │
        ▼
  TOP_OF_PAGE (Callback)    ← Report header
  USER_COMMAND (Callback)   ← Double-click → VA03
```

---

## 🚦 Traffic Light Logic

| Status Code | Meaning | Light |
|---|---|---|
| `A` | Open | 🟢 Green |
| `B` | In Process | 🟡 Yellow |
| `C` | Completed | 🟢 Green |
| `D` | Rejected / Blocked | 🔴 Red |

---

## 📋 How to Use (In SAP System)

1. Go to **SE38** → Enter program name `ZSO_ALV_REPORT` → Create
2. Paste the ABAP code from `src/ZSO_ALV_REPORT.abap`
3. Activate the program (`Ctrl + F3`)
4. Create a custom transaction `ZSO_ALV` via **SE93** pointing to this program
5. Run via `F8` or execute from the custom transaction
6. Enter selection criteria → Execute

---

## 👤 Author

| Field | Details |
|---|---|
| Name | [Your Full Name] |
| Roll No. | [Your Roll Number] |
| Batch / Program | [Your Batch Name] |
| Institute | KIIT |
| Submission Date | April 21, 2026 |

---

## 📄 Documentation

Full project documentation (Problem Statement, Solution, Code Explanation, Screenshots, Tech Stack, Future Improvements) is available in the `docs/` folder.

---

## 🚀 Future Improvements

- Add export to Excel functionality using `REUSE_ALV_GRID_DISPLAY` with download button
- Extend to include Delivery and Billing document details (LIKP, VBRK)
- Migrate to SAP Fiori / ABAP RESTful Application Programming (RAP) model
- Add email functionality to send report output via `SO_NEW_DOCUMENT_ATT_SEND_API1`
- Implement CDS Views for S/4HANA Cloud compatibility (aligned with C_ABAPD certification)
