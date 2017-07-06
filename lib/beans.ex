defmodule Beans do
  require BeanMaker
  import BeanMaker
  @moduledoc false
  @type bean :: %Beans.CoffeeBean{} | %Beans.WaxBean{} | %Beans.BlueBean{} | %Beans.ChiliBean{} | %Beans.StinkBean{}
  | %Beans.GreenBean{} | %Beans.SoyBean{} | %Beans.BlackEyedBean{} | %Beans.RedBean{}


 defprotocol Bean do
   @spec harvest(Beans.bean(), [Beans.bean()]) :: {[Beans.bean()], [Beans.bean()]}
   def harvest(bean, beanList)
   def count(bean)
 end


 defbean CoffeeBean,    count: 24,  levels: [4, 7, 10, 12]
 defbean WaxBean,       count: 22,  levels: [4, 7, 9, 11]
 defbean BlueBean,      count: 20,  levels: [4, 6, 8, 10]
 defbean ChiliBean,     count: 18,  levels: [3, 6, 8, 9]
 defbean StinkBean,     count: 16,  levels: [3, 5, 7, 8]
 defbean GreenBean,     count: 14,  levels: [3, 5, 6, 7]
 defbean SoyBean,       count: 12,  levels: [2, 4, 6, 7]
 defbean BlackEyedBean, count: 10,  levels: [2, 4, 5, 6]
 defbean RedBean,       count: 8,   levels: [2, 3, 4, 5]
end


