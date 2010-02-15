@wip
Feature: Use table multi-line step arguments

  Background:
    Given a standard Cucumber project directory structure
    And a file named "features/step_definitions/some_remote_place.wire" with:
      """
      host: localhost
      port: 3901

      """

  Scenario: Table in a Given
    Given a file named "features/table.feature" with:
      """
      Scenario: Shopping list
        Given I have a shopping list with the following items:
          | item      | count |
          | cucumbers |   3   |
          | bananas   |   5   |
          | tomatoes  |   2   |
        When I buy everything on my list
        Then my cart should contain 10 items
      """
    And Cuke4Lua started with a step definition module containing:
      """
      cuke.itemsInCart = 0

      cuke.GivenAShoppingList = {
        Given = "^I have a shopping list with the following items:$",
        Step = function(table)
          cuke.shoppingList = table
        end
      }

      cuke.BuyEverything = {
        When = "^I buy everything on my list$",
        Step = function()
          for k,v in pairs(cuke.shoppingList) do
            cuke.itemsInCart = cuke.itemsInCart + v.count
          end
        end
      }

      cuke.CartContainsNItems = {
        Then = "^my cart should contain (\d+) items$",
        Step = function(i)
          assert(cuke.itemsInCart == i)
        end
      }
      """
    When I run cucumber -f progress features
    Then STDERR should be empty
    And it should pass with
      """
      ...

      1 scenario (1 passed)
      3 steps (3 passed)

      """

  Scenario: Table in a Then
    Given a file named "features/table.feature" with:
     """
     Scenario: Build a shopping list
       Given I need 3 cucumbers
       And I need 5 bananas
       And I need 2 tomatoes
       When I build my shopping list
       Then the shopping list should look like:
         | item      | count |
         | cucumbers |   3   |
         | bananas   |   5   |
         | tomatoes  |   2   |
     """
    And Cuke4Lua started with a step definition module containing:
      """
      cuke.shoppingList = {}

      cuke.INeedNItems = {
        Given = "^I need (\d+) (.*)$",
        Step = function(count, item)
          cuke.shoppingList[item] = count
        end
      }

      cuke.IBuildMyShoppingList = {
        When = "^I build my shopping list$",
        Step = function()
          -- uhh, not sure anything actually happens here
        end
      }

      cuke.TheShoppingListShouldLookLike = {
        Then = "^the shopping list should look like:$",
        Step = function(table)
          error("TODO: table comparison")
        end
      }
      """
    When I run cucumber -b -f progress features
    Then STDERR should be empty
    And it should pass with
      """
      .....

      1 scenario (1 passed)
      5 steps (5 passed)

      """

  Scenario: Table in a Then - failed diff
    Given a file named "features/table.feature" with:
     """
     Scenario: Build a shopping list
       Given I need 3 cucumbers
       And I need 5 bananas
       And I need 2 tomatoes
       When I build my shopping list
       Then the shopping list should look like:
         | item      | count |
         | cucumbers |   3   |
         | bananas   |   5   |
       # | tomatoes  |   2   |         
     """
    And Cuke4Lua started with a step definition module containing:
      """
      cuke.shoppingList = {}

      cuke.INeedNItems = {
        Given = "^I need (\d+) (.*)$",
        Step = function(count, item)
          cuke.shoppingList[item] = count
        end
      }

      cuke.IBuildMyShoppingList = {
        When = "^I build my shopping list$",
        Step = function()
          -- uhh, not sure anything actually happens here
        end
      }

      cuke.TheShoppingListShouldLookLike = {
        Then = "^the shopping list should look like:$",
        Step = function(table)
          error("TODO: table comparison")
        end
      }
      """
    When I run cucumber -f pretty features
    Then STDERR should be empty
    And it should fail
