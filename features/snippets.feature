Feature: Print step definition snippets for undefined steps

  Background:
    Given a standard Cucumber project directory structure
    And a file named "features/step_definitions/some_remote_place.wire" with:
      """
      host: localhost
      port: 3901

      """
  
  Scenario: Undefined prints snippet
    Given a file named "features/wired.feature" with:
      """
        Scenario: Wired
          Given we're all wired

      """
    And Cuke4Lua started with no step definition modules
    When I run cucumber -f pretty
    Then the output should contain
      """
      cuke.WereAllWired = {
        pending = true,
        given = "^we're all wired$",
        step = function()
        end
      }
      """

  Scenario: Snippet with a table
    Given a file named "features/wired.feature" with:
      """
        Scenario: Wired
          Given we're all wired
            | who     |
            | Richard |
            | Matt    |
            | Aslak   |
      """
    And Cuke4Lua started with no step definition modules
    When I run cucumber -f pretty
    Then the output should contain
      """
      cuke.WereAllWired = {
        pending = true,
        given = "^we're all wired$",
        step = function(table)
        end
      }
      """

  Scenario: Snippet with a multiline string
    Given a file named "features/wired.feature" with:
      """
        Scenario: Wired
          Given we're all wired
            \"\"\"
              Lorem ipsum dolor sit amet, consectetur adipiscing elit.
              Morbi porttitor semper lobortis. Duis nec nibh felis, vitae tempor augue.
            \"\"\"
      """
    And Cuke4Lua started with no step definition modules
    When I run cucumber -f pretty
    Then the output should contain
      """
      cuke.WereAllWired = {
        pending = true,
        given = "^we're all wired$",
        step = function(s)
        end
      }
      """

  Scenario: Snippet with a scenario outline
    Given a file named "features/wired.feature" with:
      """
        Scenario Outline: Wired
          Given we're all <something>

          Examples:
          | something |
          | wired     |
          | not wired |

      """
    And Cuke4Lua started with no step definition modules
    When I run cucumber -f pretty
    Then the output should contain
      """
      cuke.WereAllWired = {
        pending = true,
        given = "^we're all wired$",
        step = function()
        end
      }
      """
    And the output should contain
      """
      cuke.WereAllNotWired = {
        pending = true,
        given = "^we're all not wired$",
        step = function()
        end
      }
      """

  Scenario: Snippet with Background
    Given a file named "features/wired.feature" with:
      """
        Background:
          Given something to do first

        Scenario: Wired
          Given we're all wired

      """
    And Cuke4Lua started with no step definition modules
    When I run cucumber -f pretty
    Then the output should contain
      """
      cuke.WereAllWired = {
        pending = true,
        given = "^we're all wired$",
        step = function()
        end
      }
      """
    And the output should contain
      """
      cuke.SomethingToDoFirst = {
        pending = true,
        given = "^something to do first$",
        step = function()
        end
      }
      """

  Scenario: Snippet for step with trailing comma
    Given a file named "features/wired.feature" with:
      """
        Scenario: Comma separated
          Given the separator is ,

      """
    And Cuke4Lua started with no step definition modules
    When I run cucumber -f pretty
    Then STDERR should be empty
    And the output should contain
      """
      cuke.TheSeparatorIs = {
        pending = true,
        given = "^the separator is ,$",
        step = function()
        end
      }
      """

   Scenario: Snippet for step with double quotes
     Given a file named "features/wired.feature" with:
      """
        Scenario: Quotes
          Given I "love" quotes

      """
     And Cuke4Lua started with no step definition modules
     When I run cucumber -f pretty
     Then the output should contain
      """
      given = "^I \"love\" quotes$",
      """
