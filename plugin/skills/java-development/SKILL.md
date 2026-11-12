---
name: java-development
description: Use for Java, Spring Boot, Maven, Gradle, Hibernate, JVM applications, services and libraries.
---
# Java development
- Inspect Java version, build tool, module layout and existing architecture first. Target OpenJDK 17/21.
- Follow existing package naming, dependency and formatting conventions. Never add wildcard imports (`import java.util.*;`); import each type explicitly.
- Build/test with `mvn clean compile` / `mvn test` or `./gradlew test`.
- Prefer clear typed APIs and immutable data where appropriate; use try-with-resources for managed resources.
- Handle exceptions meaningfully and preserve diagnostic context; do not swallow failures.
- Review Spring dependency injection, configuration, transaction boundaries and JPA fetch behaviour.
- Consider thread safety, concurrency, resource lifecycle and N+1 database queries.
- Use the project's existing test framework and run relevant Maven/Gradle tests and builds.
- Check dependency compatibility and security before upgrades; prefer official Java and Spring documentation.
- Before finishing, and whenever asked to find errors or speed something up, read `references/quality-and-performance.md` in this skill: it lists the cheapest verification commands, common error classes, how to measure, and alternatives to try. Measure before changing; report before/after.
