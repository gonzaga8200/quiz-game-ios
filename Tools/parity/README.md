# Parity fixtures

`ContrarrelojCore` is a 1:1 port of the web's `core/` (TypeScript). These fixtures are the proof:
they are produced by the **web's own code** and the Swift tests require exactly the same results.

```bash
Tools/parity/run.sh                          # web repository at ../quiz-game, ref origin/main
WEB_REPO=/path/to/quiz-game WEB_REF=v0.31.0 Tools/parity/run.sh
```

The script is read-only on the web repository: it exports `core/`, `data/questions/` and a few
`app/utils/*.ts` files of the given ref with `git archive` into a temporary directory and runs
`generate.ts` there with the web's `tsx` and `node_modules` (run `npm install` in the web repo
first). Output goes to `Packages/ContrarrelojCore/Tests/ContrarrelojCoreTests/Fixtures/`; each file
records the web commit it came from in `generatedFrom`.

| File | What it pins |
| --- | --- |
| `questions.json` | A 143-question sample (4 per category and difficulty, 2 disabled, 1 repeated id) and a fixed "seen" map |
| `rng.json` | `mulberry32` values and `shuffled` for 4 seeds |
| `queues.json` | `buildQueue` for 5 seeds × 4 filters × category × seen memory (ids, option order, correct index) |
| `games.json` | 12 scripted games: every action, its outcome, the snapshot after it, the final report |
| `boards.json`, `showcase.json`, `celebration.json`, `combo.json` | Ranking boards, category showcase, celebration tiers, combo milestones |
| `app-utils.json` | Formatting, share text and URL, `mailto:` links and keyboard shortcuts of `app/utils` |

When the web's rules change, regenerate, run `scripts/test-core.sh`, and port the change until the
tests pass again.
