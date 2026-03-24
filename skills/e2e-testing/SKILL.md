---
name: e2e-testing
description: Patrones de testing E2E con Playwright. Page Object Model, manejo de flakiness, configuración cross-browser. Usar cuando se escriban tests end-to-end.
---

# E2E Testing con Playwright

## Organización
```
tests/
├── e2e/
│   ├── auth/
│   │   ├── login.spec.ts
│   │   └── register.spec.ts
│   ├── features/
│   │   └── dashboard.spec.ts
│   └── api/
│       └── endpoints.spec.ts
├── fixtures/
│   └── test-data.ts
└── pages/
    ├── LoginPage.ts
    └── DashboardPage.ts
```

## Page Object Model
```typescript
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: 'Sign in' }).click();
  }

  async expectError(message: string) {
    await expect(this.page.getByText(message)).toBeVisible();
  }
}
```

### Beneficios
- Selectores encapsulados en clases dedicadas
- Wait for condiciones específicas (no timeouts arbitrarios)
- Mantenible cuando UI cambia

## Configuración
```typescript
// playwright.config.ts
export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [['html'], ['json', { outputFile: 'results.json' }]],
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'mobile', use: { ...devices['iPhone 14'] } },
  ],
});
```

## Combatir flakiness
1. **Cuarentena**: `test.fixme('flaky - issue #123')`
2. **Identificar**: `npx playwright test --repeat-each=10`
3. **Fixes comunes**:
   - Race conditions: `await page.waitForLoadState('networkidle')`
   - Animaciones: `await page.locator('.modal').waitFor({ state: 'visible' })`
   - NUNCA usar `page.waitForTimeout()` (sleep)

## Selectores (orden de preferencia)
1. `getByRole()` — accesibilidad first
2. `getByLabel()` — formularios
3. `getByText()` — contenido visible
4. `getByTestId()` — último recurso

## Anti-patrones
- Hardcoded waits/sleeps
- Selectores CSS frágiles
- Tests que dependen de orden de ejecución
- Tests que modifican data compartida
- Screenshots como único assertion
