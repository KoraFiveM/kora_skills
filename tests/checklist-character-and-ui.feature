# Converted from the communitybot legacy tests by kora-qa-panel/scripts/convert-legacy.mjs.
# The """ block under each Scenario is the original test text, verbatim. Review before applying.
Feature: kora_skills — Character & UI

  @kora_skills @checklist @checklist:kora_skills:open-command @cat:character-and-ui
  Scenario: Open skills panel with /skills
    """
    Checklist test: Type /skills (or /skillList) to open the Skills panel.
    """
    When I run the command "/skillList"
    Then the "kora_skills:progression" app opens
    When I run the command "/skills"
    Then the "kora_skills:progression" app should be open

  @kora_skills @checklist @checklist:kora_skills:open-key @cat:character-and-ui
  Scenario: Open skills with F4 key
    """
    Checklist test: Press F4 (rebindable, 'Open your skills'); README mentions F6 but config uses F4.
    """
    When I press the "F4" key
    Then the "kora_skills:progression" app opens
    And I confirm: the key binding is listed as 'Open your skills' in the FiveM key bindings and can be rebound

  @kora_skills @checklist @checklist:kora_skills:overview-tab @cat:character-and-ui
  Scenario: Overview: totals and XP graph
    """
    Checklist test: Overview tab shows Total experience, Combined levels, Tracked skills and per-skill progress bars.
    """
    When I run the command "/skillList"
    And I manually: open the Overview tab
    Then I confirm: the Overview tab shows Total experience, Combined levels and Tracked skills
    And I confirm: the Overview tab shows a progress bar for each skill
    And I confirm: the XP graph is displayed

  @kora_skills @checklist @checklist:kora_skills:details-table @cat:character-and-ui
  Scenario: Details tab: searchable skills table
    """
    Checklist test: Details tab lists 8 skills (mining, smelting, fishing, crafting, cooking, metal detecting, computing, hacking) with level, XP, to-next; search and sort XP.
    """
    When I run the command "/skillList"
    And I manually: open the Details tab
    Then I confirm: the table lists 8 skills: mining, smelting, fishing, crafting, cooking, metal detecting, computing, hacking
    And I confirm: each row shows level, XP and XP to next level
    When I manually: type a skill name in the search box
    Then I confirm: the table filters to matching skills
    When I manually: click the XP column header to sort
    Then I confirm: the rows are sorted by XP

  @kora_skills @checklist @checklist:kora_skills:level-up-notice @cat:character-and-ui @manual
  Scenario: Level up notification
    """
    Checklist test: Gain XP via a skill-granting activity (exports.kora_skills:addRep); 'Skill level up' notice shows the new level.
    """
    When I manually: gain XP in a skill-granting activity (for example mining or fishing) until a level is reached
    Then I confirm: a 'Skill level up' notice shows the new level of the skill

  @kora_skills @checklist @checklist:kora_skills:xp-persistence @cat:character-and-ui
  Scenario: XP persists across relog
    """
    Checklist test: Note XP/levels, relog or reconnect the character, and confirm values are unchanged (stored in SQL).
    """
    When I run the command "/skillList"
    And I manually: note the XP and level of each skill
    And I manually: relog or reconnect the character
    And I run the command "/skillList"
    Then I confirm: the XP and levels of every skill are unchanged from before

  @kora_skills @checklist @checklist:kora_skills:skill-check-bonus @cat:character-and-ui @manual
  Scenario: Skill level eases minigames
    """
    Checklist test: Higher mining/fishing/hacking level gives larger skillbar zone / fewer nodes in skill-check minigames of dependent resources.
    """
    When I manually: run a skill-check minigame of a dependent resource (mining, fishing or hacking) at a low skill level
    And I manually: raise that skill to a higher level and run the same minigame again
    Then I confirm: the skillbar zone is larger or there are fewer nodes at the higher level
