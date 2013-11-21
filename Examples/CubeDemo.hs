module Main (main) where

--------------------------------------------------------------------------------

import qualified Graphics.UI.Lambency as L
import qualified Graphics.Rendering.Lambency as LR

import Data.Vect.Float
import Data.Vect.Float.Util.Quaternion

import Data.Maybe (fromJust)
import qualified Data.Map as Map

import System.Directory
import System.FilePath
import Paths_lambency_examples

import GHC.Float (double2Float)
---------------------------------------------------------------------------------

type CubeDemoObject = UnitQuaternion

demoCam :: LR.Camera
demoCam = LR.mkPerspCamera
           -- Pos           Dir              Up
           ((-10) *& vec3Z) (mkNormal vec3Z) (mkNormal vec3Y)
           (pi / 6) (4.0 / 3.0)
           -- near far
           0.1 1000.0

cubeObj :: IO (LR.GameObject CubeDemoObject)
cubeObj = do
  putStrLn . show $ LR.getViewProjMatrix demoCam
  ro <- LR.createRenderObject LR.makeCube
  (Just tex) <- LR.loadTextureFromPNG =<< (getDataFileName $ "crate" <.> "png")
  let lu = LR.getMaterialVar (LR.material ro)
      quatToMat = (extendWith 1.0) . fromOrtho . leftOrthoU
      svMap = Map.fromList [
        (lu "mvpMatrix", (\uq c -> LR.Matrix4Val $ (quatToMat uq) .*. (LR.getViewProjMatrix c))),
        (lu "m2wMatrix", (\uq c -> LR.Matrix4Val $ (quatToMat uq)))]
  return LR.GameObject {
    LR.renderObject = Just (LR.switchMaterialTexture ro "diffuseTex" tex),
    LR.gameObject = rotU (Vec3 1 0 1) 0.6,
    LR.objSVMap = svMap,
    LR.update = \t go -> Just . (LR.updateGameObject go) $ (LR.gameObject go) .*. (rotU vec3Y $ (*0.1) $ double2Float t),
    LR.collide = \a _ -> Just a
  }

main :: IO ()
main = do
  m <- L.makeWindow 640 480 "Cube Demo"
  obj <- cubeObj
  case m of
    (Just win) -> L.run win (LR.GameCamera demoCam $ flip const) [obj]
    Nothing -> return ()
  L.destroyWindow m
