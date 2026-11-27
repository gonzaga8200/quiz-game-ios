/**
 * Writes the JSON fixtures that prove ContrarrelojCore behaves exactly like the web's core.
 * Run through Tools/parity/run.sh, which exports the web files next to this script.
 * Everything here is deterministic: the same web commit always produces the same files.
 */
import { mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import * as core from './core/index.ts'
import { describeBoard, formatClock, formatSeconds, formatSigned } from './app/utils/format.ts'
import { CONTACT_REASONS, mailtoHref, questionReportHref } from './app/utils/feedback.ts'
import { actionForKey } from './app/utils/keyboard.ts'
import { shareText, shareUrl } from './app/utils/share.ts'

const [outDir, sha] = process.argv.slice(2)
if (!outDir || !sha) throw new Error('usage: generate.ts <outDir> <webSha>')
mkdirSync(outDir, { recursive: true })

function write(name: string, data: Record<string, unknown>): void {
  writeFileSync(join(outDir, `${name}.json`), `${JSON.stringify({ generatedFrom: sha, ...data }, null, 1)}\n`)
}

// --- Question sample ---------------------------------------------------------------------------

const bank: any[] = readdirSync('data/questions')
  .filter((file) => file.endsWith('.json'))
  .sort()
  .flatMap((file) => JSON.parse(readFileSync(join('data/questions', file), 'utf8')))
const byId = [...bank].sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
const active = byId.filter((q) => q.status === 'active')

// Four questions of every category and difficulty, the first ones by id.
const sample: any[] = []
for (const category of core.CATEGORIES) {
  for (const difficulty of core.DIFFICULTIES) {
    sample.push(...active.filter((q) => q.category === category && q.difficulty === difficulty).slice(0, 4))
  }
}
const disabled = byId.filter((q) => q.status === 'disabled').slice(0, 2)
const duplicate = { ...sample[0] } // same id: the queue must keep only the first one
const questions: any[] = [...sample, ...disabled, duplicate]

const seenMap: Record<string, number> = Object.fromEntries(sample.slice(0, 30).map((q, i) => [q.id, (i % 3) + 1]))
const seenOf = (use: boolean) => (use ? new Map(Object.entries(seenMap)) : undefined)

write('questions', { questions, seen: seenMap })

// --- RNG ---------------------------------------------------------------------------------------

const seeds = [1, 42, 123456789, 4294967295]
write('rng', {
  cases: seeds.map((seed) => {
    const rng = core.mulberry32(seed)
    const values = Array.from({ length: 20 }, () => rng())
    const shuffled = core.shuffled([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], core.mulberry32(seed))
    return { seed, values, shuffled }
  }),
})

// --- Queues ------------------------------------------------------------------------------------

const firstById = new Map<string, any>()
for (const q of questions) if (!firstById.has(q.id)) firstById.set(q.id, q)

const queues: unknown[] = []
for (const seed of [1, 2, 3, 4, 5]) {
  for (const filter of core.DIFFICULTY_FILTERS) {
    for (const category of [undefined, 'Ciencias'] as const) {
      for (const useSeen of [false, true]) {
        const queue = core.buildQueue(questions, filter, core.mulberry32(seed), category, seenOf(useSeen))
        queues.push({
          seed,
          filter,
          category: category ?? null,
          seen: useSeen,
          // Option order as indexes into the stored question's options.
          queue: queue.map((p) => ({
            id: p.id,
            order: p.options.map((option) => firstById.get(p.id).options.indexOf(option)),
            correctIndex: p.correctIndex,
          })),
        })
      }
    }
  }
}
write('queues', { cases: queues })

// --- Scripted games ----------------------------------------------------------------------------

interface GameCase {
  seed: number
  filter: core.DifficultyFilter
  duration: core.Duration
  category?: core.Category
  seen?: boolean
}

const gameCases: GameCase[] = [
  { seed: 11, filter: 'Aleatorio', duration: 60 },
  { seed: 12, filter: 'Fácil', duration: 60 },
  { seed: 13, filter: 'Medio', duration: 60 },
  { seed: 14, filter: 'Difícil', duration: 60 },
  { seed: 15, filter: 'Aleatorio', duration: 120 },
  { seed: 16, filter: 'Medio', duration: 120, seen: true },
  { seed: 17, filter: 'Aleatorio', duration: 60, category: 'Ciencias' },
  { seed: 18, filter: 'Aleatorio', duration: 120, category: 'Música' },
  { seed: 19, filter: 'Difícil', duration: 120, category: 'Deportes', seen: true },
  { seed: 20, filter: 'Fácil', duration: 120, seen: true },
  { seed: 21, filter: 'Aleatorio', duration: 60, seen: true },
  { seed: 22, filter: 'Medio', duration: 60, category: 'Historia y Geografía' },
]

const snap = (s: core.GameSnapshot) => ({
  status: s.status,
  currentId: s.current?.id ?? null,
  score: s.score,
  streak: s.streak,
  bestStreak: s.bestStreak,
  correct: s.correct,
  wrong: s.wrong,
  skipped: s.skipped,
  freeSkipsLeft: s.freeSkipsLeft,
  skipCost: s.skipCost,
  remainingMs: s.remainingMs,
  finishReason: s.finishReason,
})

const games = gameCases.map((config) => {
  let now = 0
  const game = new core.Game({
    questions,
    filter: config.filter,
    duration: config.duration,
    ...(config.category ? { category: config.category } : {}),
    ...(config.seen ? { seen: seenOf(true) } : {}),
    rng: core.mulberry32(config.seed),
    now: () => now,
  })
  const steps: unknown[] = []
  const record = (action: string, extra: Record<string, unknown>, result: unknown) =>
    steps.push({ t: now, action, ...extra, result, snapshot: snap(game.snapshot()) })

  game.start()
  record('start', {}, null)

  for (let i = 0; i < 500 && game.snapshot().status === 'question'; i++) {
    const question = game.snapshot().current!
    if (i === 0) record('answer', { index: 7 }, game.answer(7)) // out of range: ignored
    now += 900 + ((i * 397 + config.seed * 131) % 2200)
    if (i % 7 === 5) {
      const outcome = game.skip()
      record('skip', {}, outcome)
      if (outcome.kind === 'skipped') record('next', {}, { status: game.next() })
    } else {
      // Seeds that are multiples of 5 build long streaks (the +8 bonus at 10); even seeds miss the
      // first question, when the score is still 0 (the score floor); the rest miss every 4th.
      const wrong =
        config.seed % 5 === 0 ? i % 13 === 12 : config.seed % 2 === 0 ? i % 4 === 0 : i % 4 === 2
      const index = wrong ? (question.correctIndex + 1) % 4 : question.correctIndex
      const outcome = game.answer(index)
      record('answer', { index }, outcome)
      if (outcome.kind === 'answered') {
        if (i === 1) record('answer', { index }, game.answer(index)) // during feedback: ignored
        now += 600
        record('next', {}, { status: game.next() })
      }
    }
  }
  now += 1000
  record('tick', {}, { status: game.tick() })

  return {
    config: { ...config, category: config.category ?? null, seen: config.seen ?? false },
    steps,
    report: game.report(),
    shownIds: game.shownIds(),
  }
})
write('games', { games })

// --- Boards, showcase, celebration, combo ------------------------------------------------------

write('boards', { boards: core.BOARDS })

write('showcase', {
  categories: core.CATEGORIES.map((category) => ({
    category,
    ids: core.pickShowcase(questions, category, 20).map((q) => q.id),
  })),
  counts: core.countActiveByCategory(questions),
})

const celebration: unknown[] = []
for (const duration of core.DURATIONS) {
  for (let points = 0; points <= 400; points += 7) {
    celebration.push({ points, duration, ...core.celebrationFor(points, duration) })
  }
}
write('celebration', { cases: celebration })

write('combo', {
  cases: Array.from({ length: 13 }, (_, streak) => ({ streak, milestone: core.nextComboMilestone(streak) })),
})

// --- App utils ---------------------------------------------------------------------------------

const site = 'https://contrarreloj-quiz.com'
const email = 'informacion@contrarreloj-quiz.com'

write('app-utils', {
  formatClock: [0, 1, 999, 1000, 1001, 9000, 59999, 60000, 60001, 65000, 119500, 120000, -5].map((ms) => ({
    ms,
    text: formatClock(ms),
  })),
  formatSeconds: [0, 4200, 4249, 4250, 999, 1050, 12345, 12345678, -3].map((ms) => ({ ms, text: formatSeconds(ms) })),
  formatSigned: [-10, -1, 0, 1, 15].map((value) => ({ value, text: formatSigned(value) })),
  describeBoard: core.BOARDS.map((b) => ({
    duration: b.duration,
    filter: b.filter,
    category: b.category ?? null,
    text: describeBoard(b.duration, b.filter, b.category),
  })),
  shareText: [0, 1, 2, 57].flatMap((points) =>
    core.DURATIONS.flatMap((duration) =>
      core.DIFFICULTY_FILTERS.flatMap((filter) =>
        ([undefined, 'Música'] as const).map((category) => ({
          points,
          duration,
          filter,
          category: category ?? null,
          emoji: '🏆',
          text: shareText({ points, duration, filter, emoji: '🏆', ...(category ? { category } : {}) }),
        })),
      ),
    ),
  ),
  shareUrl: [undefined, ...core.CATEGORIES].map((category) => ({
    category: category ?? null,
    url: shareUrl(site, category),
  })),
  contactReasons: CONTACT_REASONS,
  mailtoHref: [
    { subject: '', body: '' },
    { subject: 'Sugerencia · Contrarreloj', body: '' },
    { subject: '¿Qué tal? & más', body: 'Línea 1\nLínea 2: 100% + = ok' },
  ].map((c) => ({ email, ...c, href: mailtoHref(email, c.subject, c.body) })),
  questionReportHref: [
    { id: 'capital-francia', text: '¿Cuál es la capital de Francia?' },
    { id: 'id con espacios', text: '  Texto con espacios alrededor  ' },
    { id: 'x'.repeat(65), text: 'a'.repeat(310) },
    { id: '', text: '' },
  ].map((q) => ({ email, ...q, href: questionReportHref(email, q) })),
  actionForKey: ['1', '2', '3', '4', '5', '9', '0', 'a', 'B', 'c', 'D', 'e', 'p', 'P', 'x', ' ', 'Enter'].flatMap((key) =>
    [4, 2].map((optionCount) => ({ key, optionCount, action: actionForKey(key, optionCount) })),
  ),
})

console.log(`fixtures written to ${outDir} from ${sha}`)
