# Git Workflow

## Commits
- Formato: `<tipo>: <descripcion>`
- Tipos: feat, fix, refactor, docs, test, chore, perf, ci
- Descripcion en imperativo: "add feature" no "added feature"
- Body opcional para contexto adicional

## Pull Requests
- Revisar TODOS los commits, no solo el ultimo
- Usar `git diff [base-branch]...HEAD` para ver cambios completos
- Titulo corto (<70 chars), detalles en el body
- Incluir: resumen, cambios, plan de testing

## Branches
- Feature branches desde main/develop
- Nombres descriptivos: feature/add-auth, fix/login-error
- Borrar branches despues de merge

## Seguridad
- NUNCA commitear secrets (.env, credentials, tokens)
- NUNCA force push a main/master
- NUNCA skip hooks (--no-verify) sin razon explicita
- Verificar .gitignore incluye archivos sensibles
