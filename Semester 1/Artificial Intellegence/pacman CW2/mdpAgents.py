# mdpAgents.py
# parsons/11-nov-2017
# MDPAgent --> robinson/09-dec-2018
#
# Version 1.0
#
# A simple map-building to work with the PacMan AI projects from:
#
# http://ai.berkeley.edu/
#
# These use a simple API that allow us to control Pacman's interaction with
# the environment adding a layer on top of the AI Berkeley code.
#
# As required by the licensing agreement for the PacMan AI we have:
#
# Licensing Information:  You are free to use or extend these projects for
# educational purposes provided that (1) you do not distribute or publish
# solutions, (2) you retain this notice, and (3) you provide clear
# attribution to UC Berkeley, including a link to http://ai.berkeley.edu.
# 
# Attribution Information: The Pacman AI projects were developed at UC Berkeley.
# The core projects and autograders were primarily created by John DeNero
# (denero@cs.berkeley.edu) and Dan Klein (klein@cs.berkeley.edu).
# Student side autograding was added by Brad Miller, Nick Hay, and
# Pieter Abbeel (pabbeel@cs.berkeley.edu).

# The agent here is an extension of the above code written by Simon
# Parsons, based on the code in pacmanAgents.py

from pacman import Directions
from game import Agent
import api
import random
import game
import util
import sys

#
# A class that creates a grid that can be used as a map
#
# The map itself is implemented as a nested list, and the interface
# allows it to be accessed by specifying x, y locations.
#
class Grid:
         
    # Constructor
    #
    # Note that it creates variables:
    #
    # grid:   an array that has one position for each element in the grid.
    # width:  the width of the grid
    # height: the height of the grid
    #
    # Grid elements are not restricted, so you can place whatever you
    # like at each location. You just have to be careful how you
    # handle the elements when you use them.
    def __init__(self, width, height):
        self.width = width
        self.height = height
        subgrid = []
        for i in range(self.height):
            row=[]
            for j in range(self.width):
                row.append(0)
            subgrid.append(row)

        self.grid = subgrid

    # Print the grid out.
    def display(self):       
        for i in range(self.height):
            for j in range(self.width):
                # print grid elements with no newline
                print self.grid[i][j],
            # A new line after each line of the grid
            print 
        # A line after the grid
        print

    # The display function prints the grid out upside down. This
    # prints the grid out so that it matches the view we see when we
    # look at Pacman.
    def prettyDisplay(self):       
        for i in range(self.height):
            for j in range(self.width):
                # print grid elements with no newline
                print self.grid[self.height - (i + 1)][j],
            # A new line after each line of the grid
            print 
        # A line after the grid
        print
        
    # Set and get the values of specific elements in the grid.
    # Here x and y are indices.
    def setValue(self, x, y, value):
        self.grid[y][x] = value

    def getValue(self, x, y):
        return self.grid[y][x]

    def setScore(self, x, y, value, score):
        self.grid[y][x] = value
        self.value = score
    def getScore(self):
        return self.value

    # Return width and height to support functions that manipulate the
    # values stored in the grid.
    def getHeight(self):
        return self.height

    def getWidth(self):
        return self.width

#
# An agent that creates a map. Assigns Utilities, calculates MEU, applies Bellman, recalculates MEU.
class MDPAgent(Agent):

    # The constructor
    def __init__(self):
        print "Running init!"

        #Store values
        self.seen = []
        self.mapForFood = []
        self.mapForCap = []
        self.mapForCorners =[]
        self.mapForWall = []
    

    # This function is run when the agent is created, and it has access
    # to state information, so we use it to build a map for the agent.
    def registerInitialState(self, state):
         print "Running registerInitialState!"
         # Make a map of the right size
         self.makeMap(state)
         self.addWallsToMap(state)
         self.updateFoodInMap(state)
         self.map.display()

    # This is what gets run when the game ends.
    def final(self, state):

        print "Game Over"
        #Reset values for next game
        self.seen = []
        self.mapForFood = []
        self.mapForCap = []
        self.mapForWall = []
        


    # Make a map by creating a grid of the right size
    def makeMap(self,state):
        corners = api.corners(state)
        print corners
        height = self.getLayoutHeight(corners)
        width  = self.getLayoutWidth(corners)
        self.map = Grid(width, height)
        
        
    # Functions to get the height and the width of the grid.
    #
    # We add one to the value returned by corners to switch from the
    # index (returned by corners) to the size of the grid (that damn
    # "start counting at zero" thing again).
    def getLayoutHeight(self, corners):
        height = -1
        for i in range(len(corners)):
            if corners[i][1] > height:
                height = corners[i][1]
        return height + 1

    def getLayoutWidth(self, corners):
        width = - 1
        for i in range(len(corners)):
            if corners[i][0] > width:
                width = corners[i][0]
        return width + 1

    # Functions to manipulate the map.
    #
    # Put every element in the list of wall elements into the map
    def addWallsToMap(self, state):
        walls = api.walls(state)
        for i in range(len(walls)):
            self.map.setValue(walls[i][0], walls[i][1], '%')
            

    # Create a map with a current picture of the food that exists.
    def updateFoodInMap(self, state):
        # First, make all grid elements that aren't walls blank.
        for i in range(self.map.getWidth()):
            for j in range(self.map.getHeight()):
                if self.map.getValue(i, j) != '%':
                    self.map.setValue(i, j, ' ')
                                        
        food = api.food(state)
        for i in range(len(food)):
            self.map.setValue(food[i][0], food[i][1], '*')
        
        capsules = api.capsules(state)
        for i in range(len(capsules)):
            self.map.setValue(capsules[i][0], capsules[i][1], '&')


    #Function to create values for each item in game, used to help pacman make decision for best route
    def createMapValues(self,state):

        

        #Get items
        food = api.food(state)
        pacman = api.whereAmI(state)
        capsules = api.capsules(state)
        corners = api.corners(state)
        walls = api.walls(state)
        ghosts = api.ghosts(state)        

        #If locations not in store, add now.
        if pacman not in self.seen:
			self.seen.append(pacman)
        for i in food:
			if i not in self.mapForFood:
				self.mapForFood.append(i)
        for i in capsules:
			if i not in self.mapForCap:
				self.mapForCap.append(i)
        for i in walls:
			if i not in self.mapForWall:
				self.mapForWall.append(i)
        for i in corners:
            if i not in self.mapForCorners:
                self.mapForCorners.append(i)

        #Create dictionary from maps created above to hold locations and assign values
        #Making sure that there is enough of a reason for pacman to leave the game
        self.foodDictionary = dict.fromkeys(self.mapForFood, 3)
        self.capsuleDictionary = dict.fromkeys(self.mapForCap, 9)
        self.wallDictionary = dict.fromkeys(self.mapForWall, "%")
        self.cornerDictionary = dict.fromkeys(self.mapForCorners,"$")
        
        

        #Create mapValues to store coordinates value
        mapValues = {}
        mapValues.update(self.foodDictionary)
        mapValues.update(self.capsuleDictionary)
        mapValues.update(self.wallDictionary)
        mapValues.update(self.cornerDictionary)

        #Get everything, if not in dictionaries then set to value of -1
        for i in range(self.getLayoutWidth(corners)-1):
			for j in range(self.getLayoutHeight(corners)-1):
				if (i, j) not in mapValues.keys():
					mapValues[(i, j)] = -1
        
        #If seen food set values to seen (0) in food map
        for i in self.mapForFood:
			if i in self.seen:
				mapValues[i] = -1
		
        for i in self.mapForCap:
			if i in self.seen:
				mapValues[i] = -2
        for i in self.mapForWall:
            if i in self.seen:
                mapValues[i] = 0        

       # Set ghost value to -10 as to avoid them
        for i in mapValues.keys():
            for j in range(len(ghosts)):
                if ((int(ghosts[j][0]), int(ghosts[j][1]))) == i:
                    mapValues[i] = -10

        return mapValues
        
    # Function to calculate the maximum expected utility of a coordinate on mapValues which will then be used as the transition value for value iteration
    def calculateMEU (self, x, y, mapValues):               

		# Store utility values
        self.utilityDictionary = { "eastUtility": 0, "westUtility": 0, "northUtility": 0, "southUtility": 0}
        self.mapValues = mapValues

        self.x = x
        self.y = y
        # Get directions in relation to current position
        North = (self.x, self.y + 1)
        South = (self.x, self.y - 1)
        East = (self.x + 1, self.y)
        West = (self.x - 1, self.y)
        Wait = (self.x, self.y)
        

		# If West isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
		# 
        if self.mapValues[West] != "%":
			westUtility = (self.mapValues[West] * 0.8)
        else:
			westUtility = (self.mapValues[Wait] * 0.8)
        # If North isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[North] != "%":
			westUtility += (self.mapValues[North] * 0.1)
        else:
			westUtility += (self.mapValues[Wait] * 0.1)
        # If South isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[South] != "%":
			westUtility += (self.mapValues[South] * 0.1)
        else:
			westUtility += (self.mapValues[Wait] * 0.1)

        #Add utility to "westUtility" in dictionary
        self.utilityDictionary["westUtility"] = westUtility
        
		# Rest of directions are treated the same...
        # If East isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[East] != "%":
			eastUtility = (self.mapValues[East] * 0.8)
        else:
			eastUtility = (self.mapValues[Wait] * 0.8)
        # If North isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[North] != "%":
			eastUtility += (self.mapValues[North] * 0.1)
        else:
			eastUtility += (self.mapValues[Wait] * 0.1)
        # If South isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[South] != "%":
			eastUtility += (self.mapValues[South] * 0.1)
        else:
			eastUtility += (self.mapValues[Wait] * 0.1)

        #Add utility to "eastUtility" in dictionary
        self.utilityDictionary["eastUtility"] = eastUtility

        # If North isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[North] != "%":
			northUtility = (self.mapValues[North] * 0.8)
        else:
			northUtility = (self.mapValues[Wait] * 0.8)
        # If East isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[East] != "%":
			northUtility += (self.mapValues[East] * 0.1)
        else:
			northUtility += (self.mapValues[Wait] * 0.1)
        # If West isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[West] != "%":
			northUtility += (self.mapValues[West] * 0.1)
        else:
			northUtility += (self.mapValues[Wait] * 0.1)

        #Add utility to "northUtility" in dictionary
        self.utilityDictionary["northUtility"] = northUtility

        # If South isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[South] != "%":
			southUtility = (self.mapValues[South] * 0.8)
        else:
			southUtility = (self.mapValues[Wait] * 0.8)
        # If East isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[East] != "%":
			southUtility += (self.mapValues[East] * 0.1)
        else:
			southUtility += (self.mapValues[Wait] * 0.1)
        # If West isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[West] != "%":
			southUtility += (self.mapValues[West] * 0.1)
        else:
			southUtility += (self.mapValues[Wait] * 0.1)

        #Add utility to "southUtility" in dictionary
        self.utilityDictionary["southUtility"] = southUtility
		

		# Take the max value and make it MEU then return updated mapValues
        self.mapValues[Wait] = max(self.utilityDictionary.values())
        return self.mapValues[Wait]

    #Function to find best strategy, loop through possibilites until best action doesn't change
    def valIteration (self, state, reward, discount, values1):        

        food = api.food(state)
        capsules = api.capsules(state)
        corners = api.corners(state)
        walls = api.walls(state)
        ghosts = api.ghosts(state)

        maxHeight = self.getLayoutWidth(corners) - 1
        maxWidth = self.getLayoutHeight(corners) -1 
        
        
        #Bellman makes an appearance...
        #Vals is copy of old values
        #Cycle through possible outcomes
        #If space, value of this move is updated
        loops = 50
        while loops > 0:
            Vals = values1.copy()
            for i in range (maxHeight):
                for j in range(maxWidth):
                    if(i,j) not in food and (i,j) not in capsules and (i,j) not in walls and (i,j) not in ghosts:
                        values1[(i,j)] = reward + discount * self.calculateMEU(i, j, Vals)
            loops -=1
    
    


    # Function to move pacman in best way possible, updating after every step
    def getRules(self, state, valueMap):

        #Get previous map and reset utility
        self.mapValues = valueMap
        self.utilityDictionary = {"eastUtility": 0, "westUtility": 0, "northUtility": 0, "southUtility": 0}
        
        
        pacman = api.whereAmI(state)
        x = pacman[0]
        y = pacman[1]     

        #Predict positions just as before
        East = (x + 1, y)
        West = (x - 1, y)
        North = (x, y + 1)
        South = (x, y - 1)
        Wait = (x,y)

        #Calculate utilities of directions as before
        # If East isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[East] != "%":
			eastUtility = (self.mapValues[East] * 0.8)
        else:
			eastUtility = (self.mapValues[Wait] * 0.8)
        # If North isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still            
        if self.mapValues[North] != "%":
			eastUtility += (self.mapValues[North] * 0.1)
        else:
			eastUtility += (self.mapValues[Wait] * 0.1)
        # If South isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still        
        if self.mapValues[South] != "%":
			eastUtility += (self.mapValues[South] * 0.1)
        else:
			eastUtility += (self.mapValues[Wait] * 0.1)
        #Add utility to "eastUtility" in dictionary   
        self.utilityDictionary["eastUtility"] = eastUtility

		# Rest of directions...
        # If West isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[West] != "%":
			westUtility = (self.mapValues[West] * 0.8)
        else:
			westUtility = (self.mapValues[Wait] * 0.8)
        # If North isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[North] != "%":
			westUtility += (self.mapValues[North] * 0.1)
        else:
			westUtility += (self.mapValues[Wait] * 0.1)
        # If South isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[South] != "%":
			westUtility += (self.mapValues[South] * 0.1)
        else:
			westUtility += (self.mapValues[Wait] * 0.1)
        #Add utility to "westUtility" in dictionary
        self.utilityDictionary["westUtility"] = westUtility

        # If North isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[North] != "%":
			northUtility = (self.mapValues[North] * 0.8)
        else:
			northUtility = (self.mapValues[Wait] * 0.8)
        # If East isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[East] != "%":
			northUtility += (self.mapValues[East] * 0.1)
        else:
			northUtility += (self.mapValues[Wait] * 0.1)
        # If West isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[West] != "%":
			northUtility += (self.mapValues[West] * 0.1)
        else:
			northUtility += (self.mapValues[Wait] * 0.1)
        #Add utility to "northUtility" in dictionary
        self.utilityDictionary["northUtility"] = northUtility

        # If South isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[South] != "%":
			southUtility = (self.mapValues[South] * 0.8)
        else:
			southUtility = (self.mapValues[Wait] * 0.8)
        # If East isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[East] != "%":
			southUtility += (self.mapValues[East] * 0.1)
        else:
			southUtility += (self.mapValues[Wait] * 0.1)
        # If West isn't a wall, then multiply whatever is in this location by the expected utility (outlined in Lecture 4) or multiply expected utility of staying still
        if self.mapValues[West] != "%":
			southUtility += (self.mapValues[West] * 0.1)
        else:
			southUtility += (self.mapValues[Wait] * 0.1)
        #Add utility to "southUtility" in dictionary
        self.utilityDictionary["southUtility"] = southUtility

        #bestMEU is maxium utility
        bestMEU = max(self.utilityDictionary.values())
        #Reurn move of bestMEU
        return self.utilityDictionary.keys() [self.utilityDictionary.values().index(bestMEU)]

    #Action!
    def getAction(self, state):
        #Create map
        self.map.prettyDisplay()
        #Get utilites
        mapValues = self.createMapValues(state)
        #Update Food        
        self.updateFoodInMap(state)

        # Assign all utilities for locations in the map then apply bellman for each state with reward of 0.2 and discount of 0.8
        for i in range(self.map.getWidth()):
                for j in range(self.map.getHeight()):
                    if self.map.getValue(i,j) != "%":
                        self.map.setValue(i,j, mapValues[(i,j)])
        self.valIteration(state, .2, .8, mapValues)         
               
                
        # Get the actions we can try
        legal = api.legalActions(state)

        #If the key of best move is East, choose East
        if self.getRules(state, mapValues) == "eastUtility":
            return api.makeMove('East', legal)
        #If the key of best move is West, choose West
        if self.getRules(state, mapValues) == "westUtility":
            return api.makeMove('West', legal) 
        #If the key of best move is North, choose North
        if self.getRules(state, mapValues) == "northUtility":
            return api.makeMove('North', legal)
        #If the key of best move is South, choose South
        if self.getRules(state, mapValues) == "southUtility":
            return api.makeMove('South', legal)      
        

        # Random choice between the legal options.              
        #nextChoice = api.makeMove(random.choice(legal), legal)
        #return nextChoice


            
    
     

        
    

   
