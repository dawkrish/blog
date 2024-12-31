--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}

import Control.Monad
import Data.Monoid (mappend)
import Hakyll
import Text.Pandoc.Highlighting

main :: IO ()
main = hakyll  $ do
  match "images/*" $ do
    route idRoute
    compile copyFileCompiler

  match "css/*" $ do
    route idRoute
    compile compressCssCompiler

  match (fromList ["about.md", "contact.markdown"]) $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

  tags <- buildTags "posts/*" (fromCapture "tags/*.html")

  tagsRules tags $ \tag pattern -> do
    let title = "Posts tagged \"" ++ tag ++ "\""
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll pattern
      let ctx =
            constField "title" title
              `mappend` listField "posts" (postCtxWithTags tags) (return posts)
              `mappend` defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/tag.html" ctx
        >>= loadAndApplyTemplate "templates/default.html" ctx
        >>= relativizeUrls

  match "posts/*" $ do
    route $ setExtension "html"
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" (postCtxWithTags tags)
        >>= loadAndApplyTemplate "templates/default.html" (postCtxWithTags tags)
        >>= relativizeUrls

  create ["posts.html"] $ do
    route idRoute
    compile $ do
      posts <- recentFirst =<< loadAll "posts/*"
      let ctx =
            listField "posts" postCtx (return posts)
              `mappend` constField "title" "Posts"
              `mappend` defaultContext

      makeItem ""
        >>= loadAndApplyTemplate "templates/posts.html" ctx
        >>= loadAndApplyTemplate "templates/default.html" ctx
        >>= relativizeUrls

  create ["css/syntax.css"] $ do
    route idRoute
    compile $ do
      makeItem $ styleToCss pandocCodeStyle

  match "index.html" $ do
    route idRoute
    compile $ do
      posts <- filterM isFeatured =<< recentFirst =<< loadAll "posts/*"

      let indexCtx =
            listField "posts" postCtx (return posts)
              <> defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "404.md" $ do
    route idRoute
    compile $
      pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext

  match "templates/*" $ compile templateBodyCompiler
  where
    isFeatured item = do
      prop <- getMetadataField (itemIdentifier item) "featured"
      pure $ prop == Just "true"

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y"
    `mappend` defaultContext

--------------------------------------------------------------------------------
-- The Code I have added to default config
pandocCodeStyle :: Style
pandocCodeStyle = haddock

postCtxWithTags :: Tags -> Context String
postCtxWithTags tags = tagsField "tags" tags `mappend` postCtx

-----------------------------------------
