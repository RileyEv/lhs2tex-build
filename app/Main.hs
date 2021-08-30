{-# LANGUAGE DeriveAnyClass      #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Main where

import           Control.Monad.Trans (lift)
import           Data.Yaml           (FromJSON (..))
import           Data.Yaml.Config    (ignoreEnv, loadYamlSettings)
import           Pipeline
import           Pipeline.Internal.Core.UUID (genTaskUUID, genJobUUID)
import           Prelude             hiding (read)
import           System.FilePath     ((-<.>), (<.>))
import           System.Process

buildDissPipeline
  :: String
  -> String
  -> Circuit
       '[Var]
       '[[String]]
       '[Var]
       '[String]
       N1
buildDissPipeline outputFileName mainFileName = mapC lhs2TexTask <-> buildTexTask outputFileName mainFileName

lhs2TexTask
  :: Circuit
       '[Var]
       '[String]
       '[Var]
       '[String]
       N1
lhs2TexTask = task f
 where
  f
    :: HList' '[Var] '[String]
    -> Var String
    -> ExceptT SomeException IO ()
  f input output = do
    (HCons fInName HNil) <- lift (fetch' input)
    let fOutName = fInName -<.> "tex"
    lift (callCommand ("lhs2tex -o " ++ fOutName ++ " " ++ fInName ++ " > lhs2tex.log"))
    lift (save output fOutName)

buildTexTask
  :: String
  -> String
  -> Circuit
       '[Var]
       '[[String]]
       '[Var]
       '[String]
       N1
buildTexTask outputFileName mainFileName = task f
 where
  f
    :: HList' '[Var] '[[String]]
    -> Var String
    -> ExceptT SomeException IO ()
  f _ output = do

    lift
      (callCommand
        ("texfot --no-stderr latexmk -interaction=nonstopmode -pdf -no-shell-escape -bibtex -jobname="
        ++ outputFileName
        ++ " "
        ++ mainFileName
        )
      )
    lift (save output (outputFileName <.> "pdf"))


data Config = Config
  { mainFile   :: FilePath
  , outputName :: String
  , lhsFiles   :: [FilePath]
  }
  deriving (Generic, FromJSON, Show)

loadConfig :: IO Config
loadConfig = loadYamlSettings ["dissertation.tex-build"] [] ignoreEnv


main :: IO ()
main = do
  config <- loadConfig
  n      <-
    startNetwork (buildDissPipeline (outputName config) (mainFile config)) :: IO
      ( BasicNetwork
          '[Var]
          '[[String]]
          '[Var]
          '[String]
      )

  inputJobUUID <- genJobUUID
  inputTaskUUID <- genTaskUUID
  (inputVar :: Var [FilePath]) <- empty inputTaskUUID inputJobUUID
  save inputVar (lhsFiles config)
  write inputJobUUID (HCons' inputVar HNil') n

  _ <- output_ n


  stopNetwork n
  print "Done"
