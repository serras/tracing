{-| Non-intrusive distributed tracing

Let's assume for example we are interested in tracing the two following functions and publishing
their traces to Zipkin:

> listTaskIDs :: MonadIO m => m [Int] -- Returns a list of all task IDs.
> fetchTasks :: MonadIO m => [Int] -> m [Task] -- Resolves IDs into tasks.

We can do so simply by wrapping them inside a 'Monitor.Tracing.Zipkin.localSpan' call and adding a
'MonadTrace' constraint:

> listTaskIDs' :: (MonadIO m, MonadTrace m) => m [Int]
> listTaskIDs' = localSpan "list-task-ids" listTaskIDs
>
> fetchTasks' :: (MonadIO m, MonadTrace m) => [Int] -> m [Task]
> fetchTasks' = localSpan "fetch-tasks" . fetchTasks

Spans will now automatically get generated and published each time these actions are run! Each
publication will include various useful pieces of metadata, including lineage. For example, if we
wrap the two above functions in a root span, the spans will correctly be nested:

> main :: IO ()
> main = do
>   zipkin <- new defaultSettings
>   tasks <- run zipkin $ rootSpan "list-tasks" (listTaskIDs' >>= fetchTasks')
>   publish zipkin
>   print tasks

For clarity the above example imported all functions unqualified. In general, the recommended
pattern when using this library is to import this module unqualified and the backend-specific module
qualified. For example:

> import Monitor.Tracing
> import qualified Monitor.Tracing.Zipkin as ZPK

-}
module Monitor.Tracing (
  -- * Overview
  MonadTrace,
  -- * Generic span creation
  Sampling, alwaysSampled, neverSampled, sampledEvery, sampledWhen, debugEnabled,
  rootSpan, rootSpanWith, childSpan, childSpanWith,
  -- * Backends
  Zipkin
) where

import Control.Monad.Trace.Class
import Monitor.Tracing.Zipkin (Zipkin)