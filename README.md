# TechMentor Hub - Blockchain Mentorship & Skill Validation Platform

TechMentor Hub is a decentralized mentorship platform where experienced developers mentor learners and communities validate skill development. Built on Clarity, it connects mentors with mentees, tracks progress transparently, and rewards both parties with tokens.

## Features

- **Mentor Registration**: Register as mentor with technical expertise area
- **Mentoring Sessions**: Create structured mentor-mentee learning sessions
- **Session Reviews**: Community review and validation of session quality
- **Progress Tracking**: Document mentee learning milestones and achievements
- **Proficiency Assessment**: 1-5 scale skill level assessment by peers
- **Token Rewards**: TMH tokens for mentoring, reviews, and milestone achievements
- **Reputation System**: Build verifiable on-chain mentoring reputation
- **Active Status**: Mentors earn active status through validated sessions

## Smart Contract Functions

### Public Functions
- `register-mentor`: Create mentor profile
- `update-mentor`: Modify profile information
- `create-session`: Start new mentoring session
- `review-session`: Validate session quality
- `track-progress`: Document mentee achievements
- `assess-proficiency`: Rate mentee skill level

### Read-Only Functions
- `get-mentor-profile`: View mentor statistics and reputation
- `get-session`: Retrieve session details
- `get-session-review`: Check review status
- `get-progress-tracking`: View progress records
- `get-proficiency-assessment`: Retrieve skill assessments
- `get-total-sessions`: Count total mentoring sessions

## Rewards Structure

- Session Reviews: 5 TMH tokens
- Progress Tracking: 10 TMH × progress level
- Proficiency Milestones: 25 TMH tokens
- Mastery Achievement: 50 TMH tokens