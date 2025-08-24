# Film Financing and Profit-Sharing System

A comprehensive blockchain-based system for managing independent film production financing, investment tracking, and revenue distribution using Clarity smart contracts.

## System Overview

This system provides a decentralized platform for film financing that handles:

- **Investment Management**: Track investments, verify investors, and manage funding rounds
- **Production Budgeting**: Monitor production costs and budget allocation
- **Revenue Distribution**: Automatically distribute profits among stakeholders based on their investment shares
- **Rights Management**: Manage distribution rights and licensing agreements
- **Governance**: Enable stakeholder voting on key production decisions

## Smart Contracts

### 1. Film Registry (`film-registry.clar`)
Central registry for all film projects with basic metadata and status tracking.

### 2. Investment Manager (`investment-manager.clar`)
Handles investor verification, investment tracking, and funding round management.

### 3. Budget Tracker (`budget-tracker.clar`)
Monitors production costs, budget allocation, and expense approval workflows.

### 4. Revenue Distributor (`revenue-distributor.clar`)
Manages revenue collection and automatic distribution to stakeholders based on profit-sharing agreements.

### 5. Rights Manager (`rights-manager.clar`)
Handles distribution rights, licensing agreements, and territorial restrictions.

## Key Features

- **Transparent Financing**: All investments and expenditures are recorded on-chain
- **Automated Profit Sharing**: Revenue is automatically distributed based on predefined agreements
- **Investor Protection**: Built-in safeguards and verification processes
- **Production Oversight**: Real-time budget monitoring and cost control
- **Rights Management**: Comprehensive tracking of distribution and licensing rights

## Data Structures

- **Films**: Project metadata, status, total budget, and funding goals
- **Investors**: Verified investor profiles with investment history
- **Investments**: Individual investment records with terms and conditions
- **Expenses**: Production cost tracking with approval workflows
- **Revenue**: Income tracking and distribution records
- **Rights**: Distribution rights and licensing agreements

## Security Features

- Multi-signature requirements for large transactions
- Investor verification and accreditation checks
- Budget approval workflows
- Automated compliance with profit-sharing agreements
- Immutable audit trail for all financial transactions

## Getting Started

1. Deploy the smart contracts to the Stacks blockchain
2. Register your film project using the Film Registry
3. Set up investment terms and funding goals
4. Verify and onboard investors
5. Track production expenses and manage budget
6. Distribute revenue automatically as it's generated

## Testing

Run the comprehensive test suite:

\`\`\`bash
npm test
\`\`\`

Tests cover all contract functionality including edge cases and error conditions.

## Configuration

- `Clarinet.toml`: Clarinet configuration for local development
- `package.json`: Node.js dependencies and scripts
- Test files use Vitest for comprehensive contract testing
