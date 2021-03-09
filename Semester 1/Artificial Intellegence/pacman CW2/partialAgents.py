from pacman import Directions
from game import Agent
import api
import random
import game
import util

class PartialAgent(Agent):
		
		def __init__(self):
			self.last = Directions.STOP
			self.lastDistanceFromGhost = "x"
			
		def final(self, state):
			self.last = Directions.STOP
			self.lastDistanceFromGhost = "x"
			print "Final!"
		
		def getAction(self, state):
			# Get the actions we can try, and remove "STOP" if that is one of them.
			legal = api.legalActions(state)
			if Directions.STOP in legal:
				legal.remove(Directions.STOP)
			#get food locations
			food = api.food(state)
			if food:
				food = food[0]			
			
				
			# Where is Pacman now?
			pacman = api.whereAmI(state)		

			#Setting up variables
			win = False
			reachedX = False
			reachedY = False
			ghostInNext = False

			# Check we aren't there:
			if food:
				if pacman[0] == food[0]:
					reachedX = True
				if pacman[1] == food[1]:
					reachedY = True
			if reachedX and reachedY:
				win = True
				
			#If not and haven't won, then move towards it. First to the West, then to the EAST. Always picking random if no other options available.
			if not win and food:
				if not reachedX:
					if pacman[0] > food[0]:
						if Directions.WEST in legal:
							self.last = Directions.WEST
						else:
							pick = random.choice(legal)
							self.last = pick
					else:
						if Directions.EAST in legal:
							self.last = Directions.EAST
						else:
							pick = random.choice(legal)
							self.last = pick
				#If no X values to be found ... search the Y plane. First to the south, then to the north. Always picking random if no other options available.
				else:
					if not reachedY:
						if pacman[1] > food[1]:
							if Directions.SOUTH in legal:
								self.last = Directions.SOUTH
							else:
								pick = random.choice(legal)
								self.last = pick
						else:
							if Directions.NORTH in legal:
								self.last = Directions.NORTH
							else:
								pick = random.choice(legal)
								self.last = pick
			else:
				if not self.last in legal:
					pick = random.choice(legal)
					# Since we changed action, record what we did
					self.last = pick
			
			# Check for ghosts
			ghosts = api.ghosts(state)
			if ghosts:
				#Getting ghost positons
				ghost = ghosts[0]
				#Pacman X position
				x = pacman[0]
				#Pacman Y postion
				y = pacman[1]
				# Predict next move if moving east by...
				if self.last == Directions.EAST:
					#... adding 1 to current X postion of pacman
					x = x + 1
				# Else if .. Predict next move if moving west by...
				elif self.last == Directions.WEST:
					# ... subtracting 1 to current X position of pacman
					x = x - 1
				# Else if ... Predict next move if moving north by...
				elif self.last == Directions.NORTH:
					#... Adding 1 to current Y position of pacman
					y = y + 1
				# Else ... Predict next move if moving south by...
				else:
					#.. subtracting 1 from current Y position
					y = y - 1
				# New Pacman = X and Y values worked out from above
				newPacman = (x,y)
					
				distanceFromGhost = util.manhattanDistance(newPacman, ghost)
				
				print "nextDistance: " + str(distanceFromGhost) + " / lastDistance: " + str(self.lastDistanceFromGhost)
			else:
				distanceFromGhost = "x"
					
			# First move there is no information for self.lastDistanceFromGhost so set to any value
			if not distanceFromGhost == "x" and not self.lastDistanceFromGhost == "x":
				# If distance from ghost is smaller than the last distance for ghost OR current distance from ghost is less than 2....
				if distanceFromGhost < self.lastDistanceFromGhost or distanceFromGhost < 2:
					#If there is at least one legal choice and the last choice is legal
					if len(legal) > 1 and self.last in legal:
						print "Don't go " + str(self.last)
						#REMOVE
						legal.remove(self.last)
					#Pick from the legal choices (now not containing last move)
					pick = random.choice(legal)		
					#Updating last pick to be PICK
					self.last = pick
					print "Go " + str(pick)
			else:
				if ghosts:
					if len(legal) > 1 and self.last in legal:
						print "Don't go " + str(self.last)
						legal.remove(self.last)
					pick = random.choice(legal)									
					self.last = pick
					print "Go " + str(pick)
					
			if not distanceFromGhost == "x":
				#Setting last distance to be distance from ghost on move
				self.lastDistanceFromGhost = distanceFromGhost
			return api.makeMove(self.last, legal)
					