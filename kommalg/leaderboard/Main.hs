{-# LANGUAGE QuasiQuotes #-}
module Main where

import Control.Monad
import Data.List
import Data.Maybe
import Data.Monoid
import Data.Ord
import Text.Blaze.Html.Renderer.String
import Text.Printf
import MyHamlet

data Algebraist = MkAlgebraist
    { name     :: String
    , code     :: String
    , nick     :: String
    , url      :: String
    , awards   :: [String]
    , points   :: [Maybe Double]
    , comments :: String
    } deriving (Show,Eq,Read)

data Config = MkConfig
    { totals :: [Int]
    } deriving (Show,Eq,Read)

longestStreak :: Algebraist -> Int
longestStreak = maximum . streaks

currentStreak :: Algebraist -> Int
currentStreak = last . streaks

streaks :: Algebraist -> [Int]
streaks = (0:) . map (length . filter id) . group . map (maybe False (const True)) . points

strength :: Algebraist -> Algebraist -> Ordering
strength = mconcat
    [ flip (comparing longestStreak)
    , flip (comparing currentStreak)
    , comparing nick
    ]

main :: IO ()
main = do
    (config,ps) <- fmap read $ getContents
    writeFile "index.html" $ renderHtml $ renderLeaderboard config ps []
    forM_ ps $ \p -> do
        writeFile (code p ++ ".html") $ renderHtml $ renderLeaderboard config ps [p]
    putStrLn $ renderHtml $ renderLeaderboard config ps ps

renderAlgebraist config showPoints p = [hamlet|
  <tr>
    <td>
      <a href="#{url p}">#{nick p}
    <td>
      $forall sheet <- points p
        $if isJust sheet
          <span class="rect success">■
        $else
          <span class="rect failure">■
    $if showPoints
      <td>^{renderPoints config p}
    $else
      <td>
    <td>#{longestStreak p}
    <td>#{currentStreak p}
    <td>#{concat $ intersperse ", " $ awards p}
|]

renderPoints config p =
    let total  = sum $ map (maybe 0 id) $ points p
        maxs   = sum $ totals $ config
        ratio  = round $ 100 * total / fromIntegral maxs :: Int
        sheets = concat . intersperse ", " $ zipWith format (points p) (totals config)
        format n m
            | Nothing <- n
            = "–/" ++ show m
            | Just n' <- n
            = let n'' = floor n' :: Int
              in  if fromIntegral n'' == n'
                      then show n'' ++ "/" ++ show m
                      else show n'' ++ ",5/" ++ show m
    in [hamlet|
<span title="#{sheets}">
    #{show ratio} %
|]

renderLeaderboard config ps ps' =
    let format     = printf "%02d" :: Int -> String
    in [hamlet|
$doctype 5
<html lang="de">
  <head>
    <meta charset="utf-8">
    <title>Kommutative Algebra
    <link rel="shortcut icon" href="images/heart.ico">
    <link rel="stylesheet" type="text/css" href="http://fonts.googleapis.com/css?family=Ubuntu:regular,bold&amp;subset=latin,latin-ext">
    <style type="text/css">
      body {
        font-size: 15px;
        line-height: 24px;
        font-weight: lighter;
        font-family: Ubuntu, sans-serif;
        text-align: center;
      }
      h1 { margin: 1em 0 0.5em 0; font-weight:normal; }
      td, th { padding: 6px; }
      th { background-color: #2d1630; color: white; }
      td:first-child { font-weight: bold; }
      table { margin-left: auto; margin-right: auto; text-align: left; }
      .moral { border: 3px solid #2d1630; width: 18em; margin-left: auto; margin-right: auto; }
      .moral em { font-style: normal; }
      .remark { width: 44em; margin-left: auto; margin-right: auto; }
      .rect { font-size: 200%; }
      .success { color: #44a340; }
      .failure { color: #eeeeee; }
  <body>
    <h1>Kommutative Algebra
    <a href="http://brownsharpie.courtneygibbons.org/?p=1253">
      <img src="images/love-commute.jpeg" alt="Love makes the diagram commute." style="width: 500px; height: 333px; border: 0">
    <table>
      <tr>
        <th>AlgebraikerIn
        <th>Abgaben
        <th>Punkte
        <th>längste Strähne
        <th>aktuelle Strähne
        <th>besondere Auszeichnungen
      $forall p <- sortBy strength ps
        ^{renderAlgebraist config (elem p ps') p}
    <p>
      <em>Du willst deine Übungsblattsträhne verbessern?<br>
      <a href="skript.pdf">Skript
      <br>
      $forall n <- [0,1,2]
        <a href="uebung#{format n}.pdf">Blatt #{show n}
        <br>
    <div style="text-align: center">
      <iframe name="embed_readwrite" src="http://etherpad.wikimedia.org/p/kommutative-algebra-rueckmeldung?showControls=true&amp;showChat=false&amp;showLineNumbers=false&amp;useMonospaceFont=false" style="width: 80%; height: 20em;">
      <p>
        <a href="http://etherpad.wikimedia.org/p/kommutative-algebra-rueckmeldung">
          Das Kummerpad funktioniert nicht? Direkt zum Pad.
    <p class="moral">
      Whenever you meet a <em>functor</em>,<br>
      ask “What is its <em>codensity monad</em>?”.
|]
