notes = []
track = document.querySelector \.track
view-width = 800
hint-offset = 100
offset  = 1000
lv = 0
counter = do
  avg-diff: 0
  diff: 0
  good: 0
  ok: 0
  bad: 0
  combo: 0
  max-combo: 0
  total: 0
  gauge: 0
score = do
  density: document.querySelector('.score .density')
  diff: document.querySelector('.score .diff')
  combo: document.querySelector('.score .combo')
  max-combo: document.querySelector('.score .max-combo')
  good: document.querySelector('.indicator .good')
  ok: document.querySelector('.indicator .ok')
  lv: document.querySelector('.lv span')
  gauge: document.querySelector('.gauge .bar')

draw-gauge = ->
  score.gauge.style.width = "#{counter.gauge * 100 / 50}%"

remove = (note, hit = false) ->
  if !note.hit => note.hit = hit
  note.style.display = \none
  try
    if !note.deleted => track.removeChild note
  catch e
    console.log "try to remove a note that is not child of track"
  note.deleted = true
  counter.total += 1
  if note.hit and counter.combo > 10 =>
    counter.gauge += (2 / Math.sqrt(lv))
    draw-gauge!
  if note and !note.hit => 
    counter.combo = 0
    counter.bad += 1
    counter.gauge -= 2
    if counter.gauge < 0 => counter.gauge = 0
    draw-gauge!

replenish = (count = 100, speed = 320, sep = 200) ->
  for i from 0 til count =>
    node = document.createElement("div")
    track.appendChild(node)
    node.type = (if Math.random! > 0.5 => 1 else 2)
    node.classList.add \note, (if node.type == 1 => \don else \ka)
    node.speed = speed
    node.time = offset
    notes.push node
    offset := offset + sep

render = (elapsed) ->
  for note in notes =>
    if note.deleted => continue
    note.position = position = note.speed * (note.time - elapsed) * 0.001 + hint-offset
    note.style.left = "#{position}px"
    if position < -100 =>
      remove note
  notes := notes.filter -> !it.deleted
  sep = 20 + 180 * Math.exp(-0.05 * lv)
  len = Math.round(3 * 1000 / sep)
  if notes.length < len =>
    if counter.gauge >= 50 =>
      lv := lv + 1
      counter.gauge = 0
      draw-gauge!
      score.lv.innerHTML = lv
    #lv := lv + 1
    #sep = 20 + 180 * Math.exp(-0.05 * lv)
    #speed = (100 * 1000 / sep) * (0.99 ** lv)
    sep = 20 + 160 * Math.exp(-0.04 * lv)
    speed = (100 * 900 / sep) * (0.99 ** lv)
    replenish len, speed, sep
    score.density.innerHTML = "#{(1000)/sep}".substring(0,6)

start = 0
start-time = 0
engine = (elapsed) ->
  if !start =>
    start-time := new Date!getTime!
    start := elapsed
  render(elapsed - start - 1000)
  requestAnimationFrame(engine)

requestAnimationFrame(engine)

handler = null
document.body.addEventListener \keypress, (e) ->
  _ = (node, delay = 100) ->
    if node => node.style.display = \block
    clearTimeout handler
    handler := setTimeout (->
      score.good.style.display = \none
      score.ok.style.display = \none
      handler := null
    ), delay
  time = new Date!getTime!
  elapsed = time - start-time - 1000
  key = e.keyCode
  type = 0
  if key == 100 or key == 106 or key == 68 or key == 74 => type = 1
  if key == 101 or key == 105 or key == 69 or key == 73 => type = 2
  if !type => return
  [idx,mindiff] = [0,'NA']
  for i from 0 til 5
    note = notes[i]
    if !note => break
    diff = Math.abs(note.time - elapsed)
    if (note.position - 100) < 100 and mindiff == \NA or diff < mindiff =>
      idx = i
      mindiff = diff
  note = notes[idx]
  if mindiff != \NA and mindiff < 400 and note =>
    if type != note.type or mindiff >= 200 =>
      _ null, 0
      remove note
    else if mindiff < 80 =>
      counter.good += 1
      counter.combo += 1
      _ score.good, 100
      remove note, true
    else if mindiff < 200 =>
      counter.ok += 1
      counter.combo += 1
      _ score.ok, 100
      remove note, true
    else
      remove note
    if counter.combo > counter.max-combo => counter.max-combo = counter.combo
    counter.diff += mindiff
    counter.avg-diff = counter.diff / (counter.good + counter.ok + counter.bad)
    score.diff.innerHTML = "#{Math.round(100 * counter.avg-diff) * 0.01}".substring(0,5) + "ms"
    score.combo.innerHTML = counter.combo
    score.max-combo.innerHTML = counter.max-combo

