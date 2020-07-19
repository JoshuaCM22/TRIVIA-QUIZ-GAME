﻿package 
{
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Timer;

	public class TriviaQuizGame extends MovieClip // Created by: Joshua C. Magoliman
	{
		{

			// question data
			private var dataXML:XML;

			// text formats
			private var questionFormat:TextFormat;
			private var answerFormat:TextFormat;
			private var scoreFormat:TextFormat;
			private var hintFormat:TextFormat;

			// text fields
			private var messageField:TextField;
			private var questionField:TextField;
			private var scoreField:TextField;

			// sprites and objects
			private var gameSprite:Sprite;
			private var questionSprite:Sprite;
			private var answerSprites:Sprite;
			private var gameButton:GameButton;
			private var hintButton:GameButton;
			private var clock:Clock;

			// game state variables
			private var questionNum:int;
			private var correctAnswer:String;
			private var numQuestionsAsked:int;
			private var numCorrect:int;
			private var answers:Array;
			private var questionTimer:Timer;
			private var questionPoints:int;
			private var gameScore:int;

			public function startTriviaGame():void
			{

				// create game sprite
				gameSprite = new Sprite  ;
				addChild(gameSprite);

				// set text formats
				questionFormat = new TextFormat("Arial",24,0x330000,true,false,false,null,null,"center");
				answerFormat = new TextFormat("Arial",18,0x330000,true,false,false,null,null,"left");
				scoreFormat = new TextFormat("Arial",18,0x330000,true,false,false,null,null,"center");
				hintFormat = new TextFormat("Arial",14,0x330000,true,false,false,null,null,"center");

				// create score field and starting message text
				scoreField = createText("",questionFormat,gameSprite,0,440,550);
				messageField = createText("Loading Questions...",questionFormat,gameSprite,0,50,550);

				// set up game state and load questions
				questionNum = 0;
				numQuestionsAsked = 0;
				numCorrect = 0;
				gameScore = 0;
				showGameScore();
				xmlImport();
			}


			// start loading of questions
			public function xmlImport():void
			{
				var xmlURL:URLRequest = new URLRequest("TriviasDatabase.xml");
				var xmlLoader:URLLoader = new URLLoader(xmlURL);
				xmlLoader.addEventListener(Event.COMPLETE,xmlLoaded);
			}

			// questions loaded
			public function xmlLoaded(event:Event):void
			{
				var tempXML:XML = XML(event.target.data);
				dataXML = selectQuestions(tempXML,10);
				gameSprite.removeChild(messageField);
				messageField = createText("Get ready for the first question!",questionFormat,gameSprite,0,60,550);
				showGameButton("START");
			}

			// select a number of random questions
			public function selectQuestions(allXML:XML,numToChoose:int):XML
			{

				// create a new XML object to hold the questions
				var chosenXML:XML = <trivia></trivia>;

				// loop until we have enough
				while (chosenXML.child("*").length() < numToChoose)
				{

					// pick a random question and move it over
					var r:int = Math.floor(Math.random() * allXML.child("*").length());
					chosenXML.appendChild(allXML.item[r].copy());

					// don't use it again
					delete allXML.item[r];
				}

				// ret
				return chosenXML;
			}

			// creates a text field
			public function createText(text:String,tf:TextFormat,s:Sprite,x,y:Number,width:Number):TextField
			{
				var tField:TextField = new TextField  ;
				tField.x = x;
				tField.y = y;
				tField.width = width;
				tField.defaultTextFormat = tf;
				tField.selectable = false;
				tField.multiline = true;
				tField.wordWrap = true;
				if (tf.align == "left")
				{
					tField.autoSize = TextFieldAutoSize.LEFT;
				}
				else
				{
					tField.autoSize = TextFieldAutoSize.CENTER;
				}
				tField.text = text;
				s.addChild(tField);
				return tField;
			}

			// updates the score
			public function showGameScore():void
			{
				if ((questionPoints != 0))
				{
					scoreField.text = "Potential Points: " + questionPoints + "\t   Score: " + gameScore;
				}
				else
				{
					scoreField.text = "Potential Points: ---\t   Score: " + gameScore;
				}
			}

			// ask player if they are ready for next question
			public function showGameButton(buttonLabel:String):void
			{
				gameButton = new GameButton  ;
				gameButton.label.text = buttonLabel;
				gameButton.x = 220;
				gameButton.y = 300;
				gameSprite.addChild(gameButton);
				gameButton.addEventListener(MouseEvent.CLICK,pressedGameButton);
			}

			// player is ready
			public function pressedGameButton(event:MouseEvent):void
			{
				// clean up question
				if ((questionSprite != null))
				{
					gameSprite.removeChild(questionSprite);
				}

				// remove button and message
				gameSprite.removeChild(gameButton);
				gameSprite.removeChild(messageField);

				// ask the next question;
				if ((questionNum >= dataXML.child("*").length()))
				{
					gotoAndStop("gameover");
				}
				else
				{
					askQuestion();
				}
			}

			// set up the question
			public function askQuestion():void
			{
				// prepare new question sprite
				questionSprite = new Sprite  ;
				gameSprite.addChild(questionSprite);

				// create text field for question;
				var question:String = dataXML.item[questionNum].question;
				questionField = createText(question,questionFormat,questionSprite,0,60,550);

				// create sprite for answers, get correct answer and shuffle all
				correctAnswer = dataXML.item[questionNum].answers.answer[0];
				answers = shuffleAnswers(dataXML.item[questionNum].answers);

				// put each answer into a new sprite with a circle icon
				answerSprites = new Sprite  ;
				for (var i:int = 0; i < answers.length; i++)
				{
					var answer:String = answers[i];
					var answerSprite:Sprite = new Sprite  ;
					var letter:String = String.fromCharCode((65 + i));// A-D
					var answerField:TextField = createText(answer,answerFormat,answerSprite,0,0,450);
					var circle:Circle = new Circle  ;// from Library
					circle.letter.text = letter;
					answerSprite.x = 100;
					answerSprite.y = 190 + i * 50;
					answerSprite.addChild(circle);
					answerSprite.addEventListener(MouseEvent.CLICK,clickAnswer);
					// make it a button;
					answerSprite.buttonMode = true;
					answerSprites.addChild(answerSprite);
				}
				questionSprite.addChild(answerSprites);

				// set up a new clock;
				clock = new Clock  ;
				clock.x = 27;
				clock.y = 137.5;
				questionSprite.addChild(clock);
				questionTimer = new Timer(1000,25);
				questionTimer.addEventListener(TimerEvent.TIMER,updateClock);
				questionTimer.start();

				// place the hint button;
				hintButton = new GameButton  ;
				hintButton.label.text = "Hint";
				hintButton.x = 220;
				hintButton.y = 390;
				gameSprite.addChild(hintButton);
				hintButton.addEventListener(MouseEvent.CLICK,pressedHintButton);

				// start question points at max;
				questionPoints = 1000;
				showGameScore();
			}

			// take all the answers and shuffle them into an array
			public function shuffleAnswers(answers:XMLList)
			{
				var shuffledAnswers:Array = new Array  ;
				while (answers.child("*").length() > 0)
				{
					var r:int = Math.floor(Math.random() * answers.child("*").length());
					shuffledAnswers.push(answers.answer[r]);
					delete answers.answer[r];
				}
				return shuffledAnswers;
			}

			// update the clock
			public function updateClock(event:TimerEvent):void
			{
				clock.gotoAndStop(event.target.currentCount + 1);

				// reduce points
				questionPoints -=  25;
				showGameScore();

				if (event.target.currentCount == event.target.repeatCount)
				{
					messageField = createText("Out of time! The correct answer was:",questionFormat,gameSprite,0,190,550);
					finishQuestion();
				}
			}

			// player wants a hint
			public function pressedHintButton(event:MouseEvent):void
			{
				// remove button
				gameSprite.removeChild(hintButton);
				hintButton = null;

				// penalty
				questionPoints -=  300;
				showGameScore();

				// show hint
				var hint:String = dataXML.item[questionNum].hint;
				var hintField:TextField = createText(hint,hintFormat,questionSprite,0,390,550);
			}

			// player selects an answer
			public function clickAnswer(event:MouseEvent):void
			{

				// get selected answer text, and compare
				var selectedAnswer = event.currentTarget.getChildAt(0).text;
				if ((selectedAnswer == correctAnswer))
				{
					numCorrect++;
					messageField = createText("You got it!",questionFormat,gameSprite,0,180,550);
					gameScore +=  questionPoints;
				}
				else
				{
					messageField = createText("Incorrect! The correct answer was:",questionFormat,gameSprite,0,180,550);
				}
				finishQuestion();
			}

			public function finishQuestion():void
			{
				// remove all but the correct answer
				for (var i:int = 0; i < 4; i++)
				{
					answerSprites.getChildAt(i).removeEventListener(MouseEvent.CLICK,clickAnswer);
					if (answers[i] != correctAnswer)
					{
						answerSprites.getChildAt(i).visible = false;
					}
					else
					{
						answerSprites.getChildAt(i).y = 240;
					}
				}

				// display factoid
				var fact:String = dataXML.item[questionNum].fact;
				var factField:TextField = createText(fact,hintFormat,questionSprite,0,340,550);

				// remove hint button
				if ((hintButton != null))
				{
					gameSprite.removeChild(hintButton);
				}

				// next question
				questionTimer.stop();
				questionNum++;
				numQuestionsAsked++;
				questionPoints = 0;
				showGameScore();
				showGameButton("Continue");
			}

			// clean up sprites
			public function cleanUp():void
			{
				removeChild(gameSprite);
				gameSprite = null;
				questionSprite = null;
				answerSprites = null;
				dataXML = null;
			}
		}
	}
}