modelInfo <- list(label = "Nu-Support Vector Regression with Radial Basis Function Kernel",
                  library = "kernlab",
                  type = c("Regression", "Classification"),
                  parameters = data.frame(parameter = c('sigma', 'C', "epsilon", "nu"),,
                                          class = c("numeric", "numeric","numeric","numeric"),
                                          label = c('Sigma', "Cost", "Epsilon","Nu")),
                  grid = function(x, y, len = NULL) {
                    library(kernlab)
                    sigmas <- sigest(as.matrix(x), na.action = na.omit, scaled = TRUE)
                    expand.grid(sigma = mean(as.vector(sigmas[-2])),
                                C = 2 ^((1:len) - 3),
                                epsilon = 2 ^((1:len) - 3),
                                nu = 2 ^((1:len) - 3),
                                )
                  },
                  loop = NULL,
                  fit = function(x, y, wts, param, lev, last, classProbs, ...) {
                    if(any(names(list(...)) == "prob.model") | is.numeric(y))
                    {
                      out <- ksvm(x = as.matrix(x), y = y,
                                  kernel = rbfdot,
                                  kpar = list(sigma = param$sigma),
                                  C = param$C,
                                  epsilon = param$epsilon,
                                  nu = param$nu,


                                  , ...)
                    } else {
                      out <- ksvm(x = as.matrix(x), y = y,
                                  kernel = rbfdot,
                                  kpar = list(sigma = param$sigma),
                                  C = param$C,
                                  epsilon = param$epsilon,
                                  nu = param$nu,
                                  prob.model = classProbs,
                                  ...)
                    }

                    out
                  },
                  predict = function(modelFit, newdata, submodels = NULL) {
                    svmPred <- function(obj, x)
                    {
                      hasPM <- !is.null(unlist(obj@prob.model))
                      if(hasPM) {
                        pred <- lev(obj)[apply(predict(obj, x, type = "probabilities"),
                                               1, which.max)]
                      } else pred <- predict(obj, x)
                      pred
                    }
                    out <- try(svmPred(modelFit, newdata), silent = TRUE)
                    if(is.character(lev(modelFit)))
                    {
                      if(class(out)[1] == "try-error")
                      {
                        warning("kernlab class prediction calculations failed; returning NAs")
                        out <- rep("", nrow(newdata))
                        out[seq(along = out)] <- NA
                      }
                    } else {
                      if(class(out)[1] == "try-error")
                      {
                        warning("kernlab prediction calculations failed; returning NAs")
                        out <- rep(NA, nrow(newdata))
                      }
                    }
                    out
                  },
                  prob = function(modelFit, newdata, submodels = NULL) {
                    out <- try(predict(modelFit, newdata, type="probabilities"),
                               silent = TRUE)
                    if(class(out)[1] != "try-error")
                    {
                      ## There are times when the SVM probability model will
                      ## produce negative class probabilities, so we
                      ## induce vlaues between 0 and 1
                      if(any(out < 0))
                      {
                        out[out < 0] <- 0
                        out <- t(apply(out, 1, function(x) x/sum(x)))
                      }
                      out <- out[, lev(modelFit), drop = FALSE]
                    } else {
                      warning("kernlab class probability calculations failed; returning NAs")
                      out <- matrix(NA, nrow(newdata) * length(lev(modelFit)), ncol = length(lev(modelFit)))
                      colnames(out) <- lev(modelFit)
                    }
                    out
                  },
                  predictors = function(x, ...){
                    if(hasTerms(x) & !is.null(x@terms))
                    {
                      out <- predictors.terms(x@terms)
                    } else {
                      out <- colnames(attr(x, "xmatrix"))
                    }
                    if(is.null(out)) out <- names(attr(x, "scaling")$x.scale$`scaled:center`)
                    if(is.null(out)) out <-NA
                    out
                  },
                  tags = c("Kernel Method", "Support Vector Machines", "Radial Basis Function",
                           "Robust Methods"),
                  levels = function(x) lev(x),
                  sort = function(x) {
                    # If the cost is high, the decision boundary will work hard to
                    # adapt. Also, if C is fixed, smaller values of sigma yeild more
                    # complex boundaries
                    x[order(x$C,x$epsilon ,x$nu,x$sigma),]
                  })
