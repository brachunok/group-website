---
layout: page
permalink: /wiki/
title: wiki
description: Course notes, methods, computing guides, and shared lab knowledge.
nav: false
nav_order: 8
---

<div class="gd-kicker">
  <span>Shared knowledge</span>
  <span>Learn / Build / Reuse</span>
</div>

<p class="gd-intro">Working notes for courses, research methods, computing, and life in the lab.</p>

<figure class="gd-image-band gd-image-band--tab">
  <img src="{{ '/assets/img/projects/power-restoration.jpg' | relative_url }}" alt="A utility worker clears storm-damaged tree limbs from power lines">
  <figcaption>Methods in practice — Federal Emergency Management Agency.</figcaption>
</figure>

<div class="wiki-categories">
  <div><span>01</span><h2>Course notes</h2><p>Explanations, examples, and references developed alongside teaching.</p></div>
  <div><span>02</span><h2>Methods & models</h2><p>Practical notes on optimization, simulation, machine learning, risk, and resilience.</p></div>
  <div><span>03</span><h2>Research computing</h2><p>Reproducible workflows, software setup, data practices, and useful tools.</p></div>
  <div><span>04</span><h2>Lab handbook</h2><p>Shared expectations, procedures, and institutional knowledge.</p></div>
</div>

## Notes

<div class="wiki-index">
  {% assign wiki_pages = site.wiki | sort: "order" %}
  {% for note in wiki_pages %}
    <a class="wiki-entry" href="{{ note.url | relative_url }}">
      <span class="wiki-entry-meta">{{ note.category | default: "note" }}</span>
      <strong>{{ note.title }}</strong>
      <span>{{ note.description }}</span>
    </a>
  {% endfor %}
</div>
