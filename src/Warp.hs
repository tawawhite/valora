module Warp
  ( Warper(..)
  , warpDupe
  , warpPoly
  ) where

import Control.Lens (traverse, both, toListOf)
import Data.Traversable (mapAccumR)

import Rand
import Shape

data Warper d = Warper
  { dist :: d
  , heat :: (Point -> Double)
  }

warpDupe
  :: (Dist d, Polygon p)
  => Warper d -> Int -> Int -> p -> (Warper d, [Irregular])
warpDupe warper depth layers poly = (warper', warpedPolies)
  where
    (warper', warpedPolies) = mapAccumR (deepWarpPoly depth) warper $ take layers $ repeat poly

deepWarpPoly
  :: (Dist d, Polygon p)
  => Int -> Warper d -> p -> (Warper d, Irregular)
deepWarpPoly n warper poly = iterate (uncurry warpPoly) (warper, (Irregular (edges poly))) !! n

warpPoly
  :: (Dist d, Polygon p)
  => Warper d -> p -> (Warper d, Irregular)
warpPoly warper poly = (warper', Irregular edges')
  where
    edges' = toListOf (traverse . both) edgePairs
    (warper', edgePairs) = mapAccumR (warpEdge) warper (edges poly)

warpEdge
  :: Dist d
  => Warper d -> Edge -> (Warper d, (Edge, Edge))
warpEdge warper (Edge {start = start, end = end}) =
  (warper', (Edge {start = start, end = warped}, Edge {start = warped, end = end}))
  where
    (warper', warped) = warpPoint warper $ midpoint start end

warpPoint
  :: Dist d
  => Warper d -> Point -> (Warper d, Point)
warpPoint (Warper {dist = dist, heat = heat}) (Point {x = x, y = y}) = (warper', point')
  where
    warper' = Warper {dist = dist', heat = heat}
    point' = Point {x = x + floor (xshift * strength), y = y + floor (yshift * strength)}
    strength = heat $ Point {x = x, y = y}
    ((xshift, yshift), dist') = randPair dist

midpoint :: Point -> Point -> Point
midpoint (Point {x = x1, y = y1}) (Point {x = x2, y = y2}) = Point {x = x1 + (x2 - x1) `div` 2, y = y1 + (y2 - y1) `div` 2}