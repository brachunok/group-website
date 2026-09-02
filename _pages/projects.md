---
layout: page
title: projects
permalink: /projects/
description: Current and recent funded research from the Sustainable and Resilient Systems Lab.
nav: false
nav_order: 4
---

<div class="gd-kicker">
  <span>Funded research</span>
  <span>Climate / Infrastructure / Decisions</span>
</div>

<div class="project-funders" aria-label="Research funders">
  <a href="https://www.energy.gov/">
    <span>01</span>
    <strong>U.S. Department<br>of Energy</strong>
  </a>
  <a href="https://www.nsf.gov/">
    <span>02</span>
    <strong>National Science<br>Foundation</strong>
  </a>
  <a href="https://collaboratory.unc.edu/">
    <span>03</span>
    <strong>North Carolina<br>Collaboratory</strong>
  </a>
</div>

<div class="project-list">
  {% assign sorted_projects = site.projects | sort: "importance" %}
  {% for project in sorted_projects %}
    <a class="project-entry" href="{{ project.url | relative_url }}">
      <div class="project-number">{{ forloop.index | prepend: "0" | slice: -2, 2 }}</div>
      <div class="project-image">
        <img src="{{ project.image | relative_url }}" alt="{{ project.image_alt }}" loading="lazy">
      </div>
      <div class="project-main">
        <div class="project-meta">{{ project.funder }}{% if project.program %} / {{ project.program }}{% endif %}</div>
        <h2>{{ project.title }}</h2>
        <p>{{ project.description }}</p>
      </div>
      <div class="project-details">
        <span>{{ project.period }}</span>
      </div>
    </a>
  {% endfor %}
</div>
