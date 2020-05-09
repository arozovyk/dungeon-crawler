module Model where
import qualified Data.Map.Strict as M
import qualified Data.List as L
import qualified Keyboard as K


import Keyboard (Keyboard)
import System.Random 
import Keyboard 
import Carte
import Envi
import Data.Maybe
data Ordre = N | S | E | O | U | R deriving Show

data Modele = Model {
  carte :: Carte , 
  envi :: Envi , 
  gene :: StdGen , 
  log_m :: String , 
  keyboard :: Keyboard }

makeOrder :: Coord -> Int -> Int -> Ordre
makeOrder crd@(C x y) x2 y2  
  | (x-x2, y-y2) == ((-1),0) = E 
  | (x-x2, y-y2) == (1,0) = O 
  | (x-x2, y-y2) == (0,(-1)) = S  
  | (x-x2, y-y2) == (0,1) = N  

makeCoord :: Ordre -> Coord -> Coord 
makeCoord ord (C x y) = case ord of 
  N -> C x (y-1)  
  S -> C x (y+1)  
  O -> C (x-1) y  
  E -> C (x+1) y  




--random weighted pick the order and make a move altering the model

randomCumulate :: [(Int,Ordre)] -> Int -> Int -> (Int,Ordre) 
randomCumulate [] _ _ = error "empty Rnadom cumulate never occurs"
randomCumulate (x:xs) p acc = 
  let acc' = acc + (fst x) in 
   if (p <= acc') then x else randomCumulate xs p acc'


pickRandomWeighted :: [(Int,Ordre)] -> StdGen -> Ordre 
pickRandomWeighted l gen =
  let totalweight = foldl (\b (v,_)->b+v) 0 l in
  let (p,_) = randomR (1,totalweight) gen in
  snd (randomCumulate l p 0)



decide :: [(Int, Ordre)] -> Modele -> Entite-> Coord -> Modele
decide l m@(Model c env g lg k) ent cord =
  if (length l == 0 )then m else
  let ord = pickRandomWeighted l g in
  let remEnv = M.delete cord (contenu_envi env) in  
  let movedEnv = M.insert (makeCoord ord cord) [ent] remEnv in
    Model c (Envi movedEnv) g lg k
  

  

--see through map and envi where i can go
prevoit:: Modele -> Coord -> [(Int, Ordre)]
prevoit m@(Model c e g _ _ ) crd@(C x y) = 
  let toLookUp = [(x+1,y),(x-1,y),(x,y-1),(x,y+1)] in --r l u d 
  let cases = catMaybes $ L.map (\(cx,cy) -> (getCase2 c cx cy) ) toLookUp in 
  let passable_carte = filter (\(_,(C ax by)) -> isTraversable c ax by ) cases in 
  let passable_env = filter (\(_,crd2) -> franchissable_env crd2 e ) passable_carte in 
  let weights = getNRandom [1..4] (length passable_env) g False in 
  let ordres = map (\(_,(C x1 y1)) -> makeOrder crd x1 y1 ) passable_env in 
    zip weights ordres 
  
bouge ::RealFrac a => Modele -> Entite -> Coord -> a ->Modele
bouge m ent@(Mob id hp st) coord time = 
  let (b,a) = properFraction time in
  if((fst (properFraction time)-(round st)) `mod` 3==0) -- a step every 2 seconds (normally)
    then decide (prevoit m coord) m ent{starting_time = st +2} coord
    else m
  





stepMobs ::RealFrac a => Modele -> a -> Modele 
stepMobs m@(Model c e g l k ) time = 
  let mobs = M.filter (\x -> not $ isPlayer $ head x) (contenu_envi e) in --TODO multiple entit one case
  M.foldlWithKey (\md crd ent  -> (bouge md (head ent) crd) time) m mobs

stepPlayer ::Modele -> Modele 
stepPlayer m@(Model c e g l k ) = undefined




{-


data Etat = Perdu
    | Gagne
    | Tour {
    num_tour :: Int,
    carte_tour :: Carte,
    envi_tour :: Envi,
    gen_tour :: StdGen,
    obj_tour :: (M.Map Int Entite),
    log :: String}





data GameState = GameState { persoX :: Int
                           , persoY :: Int
                           , virusX :: Int
                           , virusY :: Int
                           , speed :: Int }
  deriving (Show)

initGameState :: IO GameState
initGameState = do
    vX <- randomRIO(40,290)
    vY <- randomRIO(40,290)
    pure $ GameState 200 200 vX vY  3

moveLeft :: GameState -> GameState
moveLeft gs@(GameState px _ _ _ sp) | px > 0 = gs { persoX = px - sp }
                                | otherwise = gs

moveRight :: GameState -> GameState
moveRight gs@(GameState px _ _ _ sp) | px < 320 = gs { persoX = px + sp }
                                 | otherwise = gs
                              
moveUp :: GameState -> GameState
moveUp gs@(GameState _ py _ _ sp) | py > 0 = gs { persoY = py - sp }
                              | otherwise = gs

moveDown :: GameState -> GameState
moveDown gs@(GameState _ py _ _ sp) | py < 320 = gs { persoY = py + sp }
                                | otherwise = gs

gameStep :: RealFrac a => GameState -> Keyboard -> a -> GameState
gameStep gstate kbd deltaTime =
  -- A MODIFIFIER
  let new_gs =if S.member KeycodeZ kbd then moveUp gstate
              else if S.member KeycodeS kbd then moveDown gstate
              else if S.member KeycodeQ kbd then moveLeft gstate
              else if S.member KeycodeD kbd then moveRight gstate
              else gstate
    in
      end_check new_gs

end_check :: GameState -> GameState
end_check gs@(GameState px py vx vy sp) = 
  if(abs(px-vx)<50 && abs(py-vy)<50)
  then GameState px py (-1) (-1) sp
  else gs
-}

