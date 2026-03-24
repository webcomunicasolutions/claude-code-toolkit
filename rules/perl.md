# Perl

## Estilo
- use v5.36 obligatorio (strict + warnings automáticos)
- Subroutine signatures
- say en lugar de print
- Moo con Types::Standard para OO
- perltidy (4-space indent, 100 chars)
- perlcritic nivel 3 mínimo

## Patrones
- Repository con DBI/DBIx::Class
- Moo para DTOs y objetos
- Three-arg open con autodie
- Path::Tiny para archivos
- Exporter con @EXPORT_OK (nunca @EXPORT)
- cpanfile + carton para dependencias

## Seguridad
- -T flag para CGI/web scripts (taint mode)
- Regex allowlist para input
- List-form system() (nunca string)
- DBI prepared statements siempre

## Testing
- Test2::V0 para proyectos nuevos
- prove -l -r para ejecutar
- Devel::Cover para cobertura (80%+)
- SIEMPRE done_testing al final
