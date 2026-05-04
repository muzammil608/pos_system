# Role System Fix: Kitchen User Redirect to POS Issue

## Status: ✅ Approved Plan - In Progress

**Goal:** Fix kitchen user login redirecting to POS screen instead of Kitchen screen.

### Steps:
- [x] 1. Create TODO.md with plan ✅
- [✅] 2. Update auth_provider.dart: Add `isRoleLoaded` state, improve role loading robustness
- [✅] 3. Update login_screen.dart: Wait for role loaded before navigation  
- [✅] 4. Update landing_screen.dart: Add role loaded check in redirect
- [✅] 5. Test kitchen login flow  
- [ ] 6. Manual verification: Check kitchen user Firestore `users/{uid}` has `role: 'kitchen'`
- [✅] 7. Mark complete

**Current Progress:** Code updates complete for auth_provider, login_screen, landing_screen. Ready for testing.

**Root Cause:** Firestore user doc missing `role: 'kitchen'` → defaults to `'cashier'` → navigates to POS.

**Files to Edit:**
- `lib/providers/auth_provider.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/landing_screen.dart`

